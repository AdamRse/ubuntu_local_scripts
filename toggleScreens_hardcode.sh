#!/bin/bash

mode_bureau() {
    # écrans
    xrandr --output "HDMI-0" --primary --mode "2560x1080" --auto --right-of "DP-1" # central
    xrandr --output "DP-1" --mode "1920x1080" --auto --left-of "HDMI-0" # gauche
    xrandr --output "DP-5" --mode "1920x1080" --auto --right-of "HDMI-0" # droite
    xrandr --output "DP-3" --off # TV

    # audio
    audio_sink_desk=$(pactl list short sinks | grep analog | awk '{print $1}')
    pactl set-default-sink $audio_sink_desk

    if pgrep -x "steam" > /dev/null; then
        steam steam://close/bigpicture
    fi
}

mode_gaming() {
    # écrans
    xrandr --output "HDMI-0" --off # central
    xrandr --output "DP-1" --off # gauche
    xrandr --output "DP-5" --off # droite
    xrandr --output "DP-3" --primary --mode "1920x1080" --auto # TV

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