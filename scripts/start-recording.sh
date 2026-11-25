#!/bin/bash

notify-send "🎥 Screen Recording" 

wf-recorder -f "$HOME/Videos/recording-$(date +%Y%m%d_%H%M%S).mp4" 

