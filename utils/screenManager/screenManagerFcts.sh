#!/bin/bash
#
# Dépendance : .env

# INIT CONST
screenlist_filename="screenList"

# SET CONST
pathfile_screenList="$CONFIG_DIR/$screenlist_filename"

# FUNCTIONS
nout() { # notification output (continue le script)
    if [ -z "$1" ]; then
        out="nout() : Erreur d'utilisation, la fonction attends une string."
        echo "$out"
        notify-send -u normal "$out"
    else
        echo "$1"
        notify-send -u normal "$1"
    fi
}
fnout() { # fail notification output (interrompt le script : exit 1)
    if [ -z "$1" ]; then
        out="fnout() : Aucun message d'erreur passé."
        echo "$out" >$2
        notify-send -u critical "$out"
    else
        echo "$1" >$2
        notify-send -u critical "$1"
    fi
    exit 1
}
wnout() { # warning notification output (continue le script)
    if [ -z "$1" ]; then
        out="wnout() : Aucun message de warning passé."
        echo "$out" >$2
        notify-send -u critical "$out"
    else
        echo "$1" >$2
        notify-send -u critical "$1"
    fi
}
save_config_file() {
    xrandr --listmonitors > "$pathfile_screenList" || fnout 
}
read_config_file(){
    return $(cat "$pathfile_screenList")
}