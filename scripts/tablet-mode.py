#!/usr/bin/env python3
"""Mode tablette pour HP Spectre x360 sous Hyprland (config Lua).

  tablet-mode.py daemon     service (lancé au démarrage d'Hyprland)
  tablet-mode.py toggle     active/désactive le mode tablette à la main
  tablet-mode.py lock       verrouille/déverrouille la rotation
  tablet-mode.py keyboard   affiche/masque le clavier virtuel (wvkbd)
  tablet-mode.py status     affiche l'état

Le mode tablette s'active tout seul quand l'écran est replié (capteur
SW_TABLET_MODE de « HP WMI hotkeys »), ou à la main avec « toggle ».
En mode tablette, l'écran interne, le tactile et le stylet suivent
l'accéléromètre. Pas de dépendance : lit /dev/input et /sys/bus/iio.
"""
import array, fcntl, glob, json, math, os, select, shutil, signal, struct, subprocess, sys, time

OUTPUT = "eDP-1"                 # écran interne
SWITCH_DEVICE = "HP WMI hotkeys" # périphérique qui porte SW_TABLET_MODE
POLL = 0.4                       # s entre deux lectures de l'accéléromètre
STABLE_READS = 2                 # lectures identiques avant de tourner
ANGLE = 35                       # degrés d'inclinaison pour changer d'orientation
# Clavier virtuel façon iPad : wvkbd compilé avec des dispositions iPad
# (~/.local/src/wvkbd-ipad). 🌐 = anglais → arabe → emoji, ⌨▾ = masquer.
KEYBOARD_BIN = os.path.expanduser("~/.local/bin/wvkbd-ipad")
KEYBOARD_NAME = "wvkbd-ipad"
KEY_CLICKS = True  # son des touches (mettre False pour couper)
CLICK_DIR = os.path.expanduser("~/.local/share/wvkbd-ipad")
IPAD_COLORS = {  # couleurs du clavier iPadOS (fond translucide + flou Hyprland)
    "light": {"bg": "d1d3d9cc", "fg": "ffffff", "fg-sp": "abb0bc", "press": "abb0bc",
              "press-sp": "ffffff", "text": "000000", "text-sp": "000000",
              "text-press": "000000", "text-press-sp": "000000", "shadow": "898a8d"},
    "dark":  {"bg": "1e1e20c4", "fg": "6b6b6e", "fg-sp": "464649", "press": "464649",
              "press-sp": "6b6b6e", "text": "ffffff", "text-sp": "ffffff",
              "text-press": "ffffff", "text-press-sp": "ffffff", "shadow": "00000059"},
}


def keyboard_cmd(hidden=True, auto=False):
    try:
        scheme = subprocess.run(["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"],
                                capture_output=True, text=True).stdout
    except OSError:
        scheme = "dark"
    colors = IPAD_COLORS["dark" if "dark" in scheme else "light"]
    # --non-exclusive : le clavier flotte par-dessus les fenêtres (ne réduit pas l'écran)
    cmd = [KEYBOARD_BIN, "-H", "440", "-L", "430", "--no-popup", "--corner-radius", "14",
           "--non-exclusive", "--wayland-layer", "overlay"]
    if KEY_CLICKS and os.path.exists(CLICK_DIR + "/click.wav"):
        cmd += ["--click", CLICK_DIR + "/click.wav", "--click-fn", CLICK_DIR + "/click-fn.wav"]
    if auto:
        # apparition automatique quand on touche un champ de texte —
        # uniquement en mode tablette
        cmd.append("--auto")
    for k, v in colors.items():
        cmd += ["--" + k, v]
    return cmd + (["--hidden"] if hidden else [])

# orientation (convention iio-sensor-proxy) -> transform Hyprland
TRANSFORMS = {"normal": 0, "left-up": 1, "bottom-up": 2, "right-up": 3}

RUNDIR = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
PIDFILE = os.path.join(RUNDIR, "tablet-mode.pid")
STATEFILE = os.path.join(RUNDIR, "tablet-mode.json")

EV_SW, SW_TABLET_MODE = 0x05, 0x01
EVENT = struct.Struct("llHHi")


# ---------- utilitaires ----------
def notify(msg):
    if shutil.which("notify-send"):
        subprocess.Popen(["notify-send", "-a", "Mode tablette", "-t", "2000", msg],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def hypr_eval(code):
    subprocess.run(["hyprctl", "eval", code], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def daemon_pid():
    try:
        pid = int(open(PIDFILE).read())
        os.kill(pid, 0)
        return pid
    except (OSError, ValueError):
        return None


def keyboard_pid():
    try:
        out = subprocess.run(["pgrep", "-x", KEYBOARD_NAME], capture_output=True, text=True).stdout.split()
        return int(out[0]) if out else None
    except (OSError, ValueError):
        return None


# ---------- capteurs ----------
def find_switch():
    for dev in glob.glob("/sys/class/input/event*"):
        try:
            if open(f"{dev}/device/name").read().strip() == SWITCH_DEVICE:
                return "/dev/input/" + os.path.basename(dev)
        except OSError:
            pass
    return None


def read_switch(fd):
    buf = array.array("B", [0] * 8)
    fcntl.ioctl(fd, (2 << 30) | (8 << 16) | (ord("E") << 8) | 0x1B, buf, True)  # EVIOCGSW
    return bool(buf[0] >> SW_TABLET_MODE & 1)


def find_accel():
    for name in glob.glob("/sys/bus/iio/devices/iio:device*/name"):
        if open(name).read().strip() == "accel_3d":
            return os.path.dirname(name)
    return None


def orientation(accel, current):
    try:
        x, y, z = (int(open(f"{accel}/in_accel_{a}_raw").read()) for a in "xyz")
    except (OSError, ValueError):
        return current
    norm = math.sqrt(x * x + y * y + z * z) or 1
    if abs(z) / norm > 0.9:          # tablette posée à plat : on ne touche à rien
        return current
    portrait = math.degrees(math.atan2(x, math.hypot(y, z)))
    landscape = math.degrees(math.atan2(y, math.hypot(x, z)))
    if abs(portrait) > ANGLE and abs(portrait) > abs(landscape):
        return "left-up" if portrait > 0 else "right-up"
    if abs(landscape) > ANGLE:
        return "bottom-up" if landscape > 0 else "normal"
    return current


# ---------- actions ----------
def monitor_info():
    try:
        mons = json.loads(subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True).stdout)
        return next((m for m in mons if m["name"] == OUTPUT), None)
    except (ValueError, OSError):
        return None


def rotate(name, base):
    t = TRANSFORMS[name]
    m = monitor_info() or {}
    mode = base.get("mode", "preferred")
    pos = f'{m.get("x", 0)}x{m.get("y", 0)}'
    scale = m.get("scale", 1)
    hypr_eval(
        f'hl.monitor({{ output = "{OUTPUT}", mode = "{mode}", position = "{pos}", scale = {scale}, transform = {t} }}) '
        f'hl.config({{ input = {{ touchdevice = {{ output = "{OUTPUT}", transform = {t} }}, '
        f'tablet = {{ output = "{OUTPUT}", transform = {t} }} }} }})'
    )


def keyboard(tablet):
    """Entrée en mode tablette : (re)lance le clavier caché avec --auto.
    Sortie : ferme le clavier (et donc l'apparition automatique)."""
    pid = keyboard_pid()
    if pid:  # un clavier lancé à la main (sans --auto) est remplacé
        os.kill(pid, signal.SIGTERM)
        for _ in range(20):
            if not keyboard_pid():
                break
            time.sleep(0.05)
    if tablet and os.access(KEYBOARD_BIN, os.X_OK):
        subprocess.Popen(keyboard_cmd(hidden=True, auto=True), stdout=subprocess.DEVNULL,
                         stderr=subprocess.DEVNULL, start_new_session=True)


def tablet_active():
    try:
        with open(STATEFILE) as f:
            return bool(json.load(f).get("tablet"))
    except (OSError, ValueError):
        return False


# ---------- service ----------
def daemon():
    if daemon_pid():
        sys.exit("déjà lancé")
    open(PIDFILE, "w").write(str(os.getpid()))

    sw_path, accel = find_switch(), find_accel()
    sw = open(sw_path, "rb", buffering=0) if sw_path else None
    m = monitor_info() or {}
    base = {"mode": f'{m["width"]}x{m["height"]}@{m["refreshRate"]:.3f}'} if m else {}

    st = {"hw": read_switch(sw) if sw else False, "forced": None, "locked": False}
    applied, pending, count = "normal", None, 0
    active_prev = None

    def on_toggle(*_):
        st["forced"] = not (st["forced"] if st["forced"] is not None else st["hw"])

    def on_lock(*_):
        st["locked"] = not st["locked"]
        notify("Rotation verrouillée" if st["locked"] else "Rotation automatique")

    def on_exit(*_):
        raise SystemExit

    signal.signal(signal.SIGUSR1, on_toggle)
    signal.signal(signal.SIGUSR2, on_lock)
    signal.signal(signal.SIGTERM, on_exit)
    signal.signal(signal.SIGINT, on_exit)

    try:
        while True:
            try:
                ready, _, _ = select.select([sw] if sw else [], [], [], POLL)
            except InterruptedError:
                ready = []
            if ready:
                data = sw.read(EVENT.size * 16) or b""
                for i in range(0, len(data) - EVENT.size + 1, EVENT.size):
                    _, _, typ, code, val = EVENT.unpack_from(data, i)
                    if typ == EV_SW and code == SW_TABLET_MODE:
                        st["hw"], st["forced"] = bool(val), None  # le pli reprend la main

            active = st["forced"] if st["forced"] is not None else st["hw"]
            if active != active_prev:
                notify("Mode tablette activé" if active else "Mode ordinateur")
                keyboard(active)
                if not active and applied != "normal":
                    rotate("normal", base)
                    applied = "normal"
                active_prev, pending, count = active, None, 0

            if active and not st["locked"] and accel:
                o = orientation(accel, applied)
                count = count + 1 if o == pending else 1
                pending = o
                if o != applied and count >= STABLE_READS:
                    rotate(o, base)
                    applied = o

            with open(STATEFILE, "w") as f:
                json.dump({"tablet": active, "hw_folded": st["hw"], "forced": st["forced"],
                           "locked": st["locked"], "orientation": applied}, f)
    except SystemExit:
        pass
    finally:
        if applied != "normal":
            rotate("normal", base)
        keyboard(False)
        for f in (PIDFILE, STATEFILE):
            try:
                os.remove(f)
            except OSError:
                pass


def send(sig):
    pid = daemon_pid()
    if not pid:
        sys.exit("le service tablet-mode n'est pas lancé")
    os.kill(pid, sig)


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    if cmd == "daemon":
        daemon()
    elif cmd == "toggle":
        send(signal.SIGUSR1)
    elif cmd == "lock":
        send(signal.SIGUSR2)
    elif cmd == "keyboard":
        pid = keyboard_pid()
        if pid:
            os.kill(pid, signal.SIGRTMIN)  # wvkbd : SIGRTMIN = afficher/masquer
        elif os.access(KEYBOARD_BIN, os.X_OK):
            # Super+K / icône : clavier manuel ; --auto seulement en mode tablette
            subprocess.Popen(keyboard_cmd(hidden=False, auto=tablet_active()), stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL, start_new_session=True)
        else:
            notify("Clavier virtuel absent : recompile ~/.local/src/wvkbd-ipad")
    elif cmd == "status":
        try:
            print(open(STATEFILE).read())
        except OSError:
            print("service arrêté")
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
