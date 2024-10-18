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

# Attendre qu'une fenêtre soit créée
wait_for_window() {
    while [ -z "$(xdotool search --name "$1")" ]; do
        sleep 1
    done
}
# Fermer toutes les fenêtres
close_all_windows() {
    echo "Closing all windows..."
    windows=$(xdotool search --onlyvisible --name ".*")
    for window in $windows; do
        xdotool windowclose $window
    done
    sleep 1
    echo "All windows closed."
}

# Lancement de Firefox sur l'écran de droite (DP-3)
firefox "${FIREFOX_TABS[@]}" &
wait_for_window "Mozilla Firefox"
firefox_window=$(xdotool search --name "Mozilla Firefox" | tail -n 1)
xdotool windowsize $firefox_window 500 500
xdotool windowmove $firefox_window 4480 0
xdotool windowactivate $firefox_window key F10

# Lancement de VS Code sur l'écran du milieu (HDMI-0)
code "$PROJECT_DIR" &
wait_for_window "Visual Studio Code"
vscode_window=$(xdotool search --name "Visual Studio Code" | tail -n 1)
xdotool windowmove $vscode_window 1920 0
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