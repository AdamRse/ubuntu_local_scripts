#!/bin/bash

# Définir les noms des sorties vidéo
MONITOR_LEFT="DP-5"
MONITOR_MIDDLE="HDMI-0"
MONITOR_RIGHT="DP-1"

# Définir la sortie audio, id obtenu via la commande pactl list short sinks
AUDIO_SINK_TV=$(pactl list short sinks | grep hdmi | awk '{print $1}')
AUDIO_SINK_DESK=$(pactl list short sinks | grep analog | awk '{print $1}')

# Vérifier l'état actuel des écrans
IS_LEFT_ON=$(xrandr --listmonitors | grep -w $MONITOR_LEFT)
IS_MIDDLE_ON=$(xrandr --listmonitors | grep -w $MONITOR_MIDDLE)

timeout=60
elapsed=0

# Fonction pour éteindre les écrans gauche et milieu, et rediriger l'audio
mode_gaming_canap() {
    # Désactiver les écrans gauche et milieu
    xrandr --output $MONITOR_LEFT --off
    xrandr --output $MONITOR_MIDDLE --off
    
    # Mettre l'écran de droite en écran principal
    xrandr --output $MONITOR_RIGHT --primary --auto

    AUDIO_SINK_TV=$(pactl list short sinks | grep hdmi | awk '{print $1}')
    echo "audio détecté pour la TV : >$AUDIO_SINK_TV<"

    AUDIO_SINK_TV=$(pactl list short sinks | grep hdmi | awk '{print $1}')

    # Rediriger l'audio vers la TV
    pactl set-default-sink $AUDIO_SINK_TV
    pactl set-sink-volume $AUDIO_SINK_TV 100%
    echo "Paramétrage de la sortie audio sur $AUDIO_SINK_TV"

    # Boucle qui retente de récupérer AUDIO_SINK_TV
    while [ -z "$AUDIO_SINK_TV" ] && [ $elapsed -lt $timeout ]; do
        AUDIO_SINK_TV=$(pactl list short sinks | grep hdmi | awk '{print $1}')
        
        if [ -z "$AUDIO_SINK_TV" ]; then
            echo "Aucune sortie HDMI détectée. Tentative à nouveau dans 1 seconde..."
            sleep 1
            ((elapsed+=1))
        else
            pactl set-default-sink $AUDIO_SINK_TV
            pactl set-sink-volume $AUDIO_SINK_TV 100%
            echo "Paramétrage de la sortie audio sur $AUDIO_SINK_TV"
        fi
    done

    steam steam://open/bigpicture

    echo "Fin de la boucle, audio trouvé : >$AUDIO_SINK_TV<"
    
    echo "Les écrans $MONITOR_LEFT et $MONITOR_MIDDLE ont été éteints. $MONITOR_RIGHT est maintenant l'écran principal. L'audio est redirigé vers la TV."
}

# Fonction pour le mode gaming PC (nouvel écran central uniquement)
mode_gaming_pc() {
    # Désactiver les écrans latéraux
    xrandr --output $MONITOR_LEFT --off
    xrandr --output $MONITOR_RIGHT --off
    
    # Activer l'écran du milieu en tant qu'écran principal
    xrandr --output $MONITOR_MIDDLE --primary --auto

    # Configurer l'audio sur la sortie bureau
    AUDIO_SINK_DESK=$(pactl list short sinks | grep analog | awk '{print $1}')
    pactl set-default-sink $AUDIO_SINK_DESK
    
    echo "Mode gaming PC activé : écrans latéraux désactivés, écran central en principal"
}

# Fonction pour allumer les écrans gauche et milieu en mode "joindre"
mode_bureau() {
    AUDIO_SINK_DESK=$(pactl list short sinks | grep analog | awk '{print $1}')

    # Activer l'écran gauche et le placer à gauche de l'écran du milieu
    xrandr --output $MONITOR_LEFT --auto --left-of $MONITOR_MIDDLE
    
    # Activer l'écran du milieu et le placer à droite de l'écran gauche
    xrandr --output $MONITOR_MIDDLE --primary --auto --right-of $MONITOR_LEFT
    
    # S'assurer que l'écran de droite est toujours en mode "joindre"
    xrandr --output $MONITOR_RIGHT --auto --right-of $MONITOR_MIDDLE
    
    # Rediriger l'audio vers la sortie analogique
    pactl set-default-sink $AUDIO_SINK_DESK

    # Si steam est lancé, quitter le mode big pictures
    if pgrep -x "steam" > /dev/null
    then
        steam steam://close/bigpicture
    fi

    echo "Les écrans $MONITOR_LEFT et $MONITOR_MIDDLE ont été allumés et configurés en mode joindre. $MONITOR_MIDDLE est maintenant l'écran principal. L'audio est redirigé vers la sortie analogique."
}

# PROGRAMME

# Vérification de l'argument $1
if [[ "$1" == "desk" ]]; then
    mode_bureau
elif [[ "$1" == "tv" ]]; then
    mode_gaming_canap
elif [[ "$1" == "gaming_desk" ]]; then
    mode_gaming_pc
else # Si aucun argument n'est passé, on fait un switch
    if [ -n "$IS_LEFT_ON" ] || [ -n "$IS_MIDDLE_ON" ]; then
        mode_gaming_canap
    else
        mode_bureau
    fi
fi