#!/usr/bin/env bash

#JSON="$HOME/.config/hypr/scripts/hadiths/bukhari.json"

# Count hadiths
#count=$(jq '.hadiths | length' "$JSON")

# Random index
#index=$((RANDOM % count))

# Extract fields
#arabic=$(jq -r ".hadiths[$index].arabic" "$JSON")
#english=$(jq -r ".hadiths[$index].english.text" "$JSON")

# Extract ONLY the main hadith text inside quotes
#hadith_only=$(echo "$arabic" | sed -n 's/.*\\"[[:space:]]*\([^"]*\)[[:space:]]*\\".*/\1/p')

# If extraction fails (no quotes), fall back to full Arabic
#if [ -z "$hadith_only" ]; then
#  hadith_only="$arabic"
#fi

# Break Arabic every 8 words
#arabic_wrapped=$(echo "$arabic" |
#  awk '{
#    for (i=1; i<=NF; i++) {
#      printf "%s ", $i
#      if (i % 8 == 0) printf "\n"
#    }
#  }')

#printf "<span allow_breaks=\"true\" font_desc=\"Noto Naskh Arabic 20\">%s</span>\n\n<span allow_breaks=\"true\" font_desc=\"Noto Sans 14\">%s</span>" \
#  "$arabic_wrapped" "$english"
#
JSON="$HOME/.config/hypr/scripts/hadiths/bukhari.json"
max_chars=250 # adjust to taste (150 = very short, 300 = medium)
max_words=40  # extra safety (skip very wordy chains)

total=$(jq '.hadiths | length' "$JSON")

while true; do
  index=$((RANDOM % total))

  arabic=$(jq -r ".hadiths[$index].arabic" "$JSON")
  english=$(jq -r ".hadiths[$index].english.text" "$JSON")

  # count characters and words in Arabic text
  length_chars=$(echo -n "$arabic" | wc -m)
  length_words=$(echo "$arabic" | wc -w)

  # skip if too large
  if [ "$length_chars" -gt "$max_chars" ] || [ "$length_words" -gt "$max_words" ]; then
    continue
  fi

  # found a small hadith → stop
  break
done

# wrap Arabic every 8 words (optional)
arabic_wrapped=$(echo "$arabic" | awk '
{
  for (i=1; i<=NF; i++) {
    printf "%s ", $i;
    if (i % 8 == 0) printf "\n";
  }
}')

# Output formatted for Hyprlock
printf "<span allow_breaks=\"true\" font_desc=\"Noto Naskh Arabic 22\">%s</span>\n\n<span allow_breaks=\"true\" font_desc=\"Noto Sans 14\">%s</span>" \
  "$arabic_wrapped" "$english"
