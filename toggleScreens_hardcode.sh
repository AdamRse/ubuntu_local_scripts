#!/bin/bash

# HDMI-0 : écran central
# DP-1   : écran gauche
# DP-5   : écran droite
# DP-3   : TV

mode_bureau() {
    # écrans
    xrandr --output "DP-1" --mode "1920x1080" --pos 0x0 \
        --output "HDMI-0" --mode "2560x1080" --primary --right-of "DP-1" \
        --output "DP-5" --mode "1920x1080" --right-of "HDMI-0" \
        --output "DP-3" --off

    # audio
    audio_sink_desk=$(pactl list short sinks | grep analog | awk '{print $1}')
    pactl set-default-sink $audio_sink_desk

    if pgrep -x "steam" > /dev/null; then
        steam steam://close/bigpicture
    fi
}

mode_gaming() {
    # écrans
    xrandr --output "DP-1" --off \
        --output "HDMI-0" --off \
        --output "DP-5" --off \
        --output "DP-3" --mode "1920x1080" --primary

    # audio
    audio_sink_tv=$(pactl list short sinks | grep hdmi | awk '{print $1}')
    pactl set-default-sink $audio_sink_tv
    pactl set-sink-volume $audio_sink_tv 100%

    steam steam://open/bigpicture
}

# Programme principal
if [[ "$1" == "desk" ]]; then
    mode_bureau
elif [[ "$1" == "tv" ]]; then
    mode_gaming
else
    if [ -n "$1" ]; then
        err_msg="Aucun paramètre passé."
    else
        err_msg="paramètre '$1' non valide."
    fi
    notify-send -u "critical" -a "Toggle Screen" "$err_msg"
fi