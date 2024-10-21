#!/bin/bash

# Définition des variables
PROJECT_DIR="/home/adam/dev/vestiaire-back"
FIREFOX_TABS=(
    "https://www.youtube.com/watch?v=5yx6BWlEVcY"
    "https://app.slack.com/client/T05AXRNBC7L/C05BMHDKW56"
    #"https://trello.com/b/pp2FJVV5/vestiaire-officiel-ecommerce"
    "https://github.com/AdamRse/vestiaire-officiel-back"
    "http://5.39.77.77/phpmyadmin/index.php?route=/&route=%2F&db=vestiaire-officiel"
    "https://claude.ai/new"
    "https://martian-water-465486.postman.co/workspace/Vestiaire-Officiel~20421df4-cbfd-465d-ac95-b09edb13c034/overview"
)
CURRENT_WINDOW=$(xdotool getactivewindow)

# Attendre qu'une fenêtre soit créée
wait_for_window() {
    while [ -z "$(xdotool search --name "$1")" ]; do
        sleep 0.1
    done
    sleep 0.9
}
# Fermer toutes les fenêtres
close_all_windows() {
     # Obtenir l'ID de la fenêtre du terminal actuel
    CURRENT_WINDOW=$(xdotool getactivewindow)

    # Fonction pour obtenir toutes les fenêtres (visibles et minimisées)
    get_all_windows() {
        wmctrl -l | awk '{print $1}'
    }

    # Fermer toutes les fenêtres sauf celle du script
    for WINDOW in $(get_all_windows); do
        # Vérifier si la fenêtre existe toujours et n'est pas celle du script
        if [ "$WINDOW" != "$CURRENT_WINDOW" ] && xprop -id "$WINDOW" &>/dev/null; then
            wmctrl -ic "$WINDOW"
            echo "Fermeture de la fenêtre avec ID: $WINDOW"
        fi
    done

    echo "Toutes les fenêtres (sauf celle-ci) ont été fermées."
}
# Pour lancer un programme
launch_program() {
    local program="$1"
    local options="$2"
    local position_x="$3"
    local position_y="$4"
    local size_width="$5"
    local size_height="$6"
    local fullscreen="${7:-0}"
    local window_name="$8"

    # Lancer le programme
    $program $options &

    # Attendre que la fenêtre soit créée
    wait_for_window "$window_name"

    # Obtenir l'ID de la fenêtre
    local window_id=$(xdotool search --name "$window_name" | tail -n 1)

    # Déplacer et redimensionner la fenêtre
    xdotool windowmove $window_id $position_x $position_y
    xdotool windowsize $window_id $size_width $size_height

    # Mettre en plein écran si nécessaire
    if [ "$fullscreen" -eq 1 ]; then
        xdotool windowactivate $window_id key alt+F10
    fi
}
close_all_windows
sleep 0.5

# # Lancement de Firefox
# launch_program "firefox" "${FIREFOX_TABS[*]}" 4480 -30 1080 1080 0 "Mozilla Firefox"

# # Lancement de VS Code
# launch_program "code" "$PROJECT_DIR" 1920 0 2560 1080 1 "Visual Studio Code"

# # Lancement du premier terminal (projet Laravel)
# launch_program "gnome-terminal" "--working-directory=$PROJECT_DIR -- bash -c \"git pull origin master && php artisan serve; exec bash\"" 960 770 990 400 0 "Terminal"

# # Lancement du deuxième terminal
# launch_program "gnome-terminal" "--working-directory=$PROJECT_DIR" 960 -30 990 800 0 "adam@adam-Z690-UD-AX:"

# # Lancement de Discord
# launch_program "discord" "start" 0 0 985 1080 0 "Discord"

# Lancement de Firefox sur l'écran de droite (DP-3)
firefox "${FIREFOX_TABS[@]}" &
wait_for_window "Mozilla Firefox"
firefox_window=$(xdotool search --name "Mozilla Firefox" | tail -n 1)
xdotool windowmove $firefox_window 4480 -30
xdotool windowsize $firefox_window 1080 100%
#xdotool windowactivate $firefox_window key alt+F10

# Lancement de VS Code sur l'écran du milieu (HDMI-0)
code "$PROJECT_DIR" &
wait_for_window "Visual Studio Code"
vscode_window=$(xdotool search --name "Visual Studio Code" | tail -n 1)
xdotool windowmove $vscode_window 1920 0 &
xdotool windowsize $vscode_window 2560 100%
xdotool windowactivate $vscode_window key alt+F10

# Lancement du premier terminal (projet Laravel)
gnome-terminal --working-directory="$PROJECT_DIR" -- bash -c "git pull origin master && php artisan serve; exec bash" &
#wait_for_window "adam@adam-Z690-UD-AX:"
wait_for_window "Terminal"
terminal1_window=$(xdotool search --name "Terminal" | tail -n 1)
xdotool windowsize $terminal1_window 990 400
xdotool windowmove $terminal1_window 960 770

# Lancement du deuxième terminal (répertoire du projet)
gnome-terminal --working-directory="$PROJECT_DIR" &
wait_for_window "adam@adam-Z690-UD-AX:"
terminal2_window=$(xdotool search --name "adam@adam-Z690-UD-AX:" | tail -n 1)
xdotool windowsize $terminal2_window 990 800
xdotool windowmove $terminal2_window 960 -30
xdotool windowactivate $terminal2_window 

# Lancement de Discord sur la partie gauche de l'écran de gauche (DP-1)
discord start &
wait_for_window "Discord"
discord_window=$(xdotool search --name "Discord" | tail -n 1)
xdotool windowmove $discord_window 0 0
xdotool windowsize $discord_window 985 1080



xdotool windowactivate $vscode_window

sleep 2
firefox "http://127.0.0.1:8000"

echo "Environnement de travail lancé avec succès !"

exit 0