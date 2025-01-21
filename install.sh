#!/bin/bash

# Installation de l'architecture perso
ARCHITECTURE_PERSO=true
while true; do
    read -n 1 -p "Appliquer l'architecture personnelle ? (o/n) " response_architecture
    # Vérification de la réponse
    if [[ $response_architecture == "o" ]]; then
        break
    elif [[ $response_architecture == "n" ]]; then
        ARCHITECTURE_PERSO=false
        break
    else
        echo "Réponse invalide. Veuillez entrer 'o' (Oui) ou 'n' (Non)."
    fi
done


#Pour trouver le dossier home de l'utilisateur, même si le script est lancé en sudo
if [ "$(id -u)" -eq 0 ]; then #On est en sudo
    HOME_FOLDER="/home/$(whoami)"
    if ! [ -d "$HOME_FOLDER" ]; then # Le dossier perso n'a pas été trouvé
        echo "Erreur, impossible de trouver le dossier /home/<user>, le nom d'utilisateur ne correspond à aucun répertoire de /home.\nRelancez le programme sans droits d'administrateur (sans sudo)."
        exit 1
    fi
else
    HOME_FOLDER=$HOME
fi


#On créé l'architecture perso et on déplace le répertoire local_scripts si besoin
PATH_LOCAL_SCRIPTS="$HOME_FOLDER/dev/local_scripts"
if [ $ARCHITECTURE_PERSO ] && ! [ $PWD == "$PATH_LOCAL_SCRIPTS"]; then # Si on doit respecter l'architecture ~/dev/local_scripts
    if ! [ -d "$PATH_LOCAL_SCRIPTS" ]; then # Si  ~/dev/local_scripts n'existe pas on le créé et on bouge le repo dedans
        echo "Création du répertoire '$PATH_LOCAL_SCRIPTS'"
        mkdir -p "$PATH_LOCAL_SCRIPTS"
        echo "Déplacement dans le répertoire '$PATH_LOCAL_SCRIPTS'"
        mv "$PWD" "$PATH_LOCAL_SCRIPTS"
    else # Sinon on attend une réponse de l'utilisateur, le script install n'est pas executé depuis ~/dev/local_scripts mais ~/dev/local_scripts existe. Faut-il l'écraser et prendre sa place ?
        while true; do
            read -n 1 -p "Le répertoire '$PATH_LOCAL_SCRIPTS' existe déjà, mais le script est executé depuis '$PWD'. écraser '$PATH_LOCAL_SCRIPTS' pour y déplacer le repository de '$PWD' ? (o/n) " response_ecraser
            # Vérification de la réponse
            if [[ $response_ecraser == "o" ]]; then
                echo "Supression de '$PATH_LOCAL_SCRIPTS'"
                sudo rm -rf $PATH_LOCAL_SCRIPTS
                echo "Création du répertoire vide '$PATH_LOCAL_SCRIPTS'"
                mkdir -p "$PATH_LOCAL_SCRIPTS"
                echo "Déplacement dans le répertoire '$PATH_LOCAL_SCRIPTS'"
                mv "$PWD" "$PATH_LOCAL_SCRIPTS"
                break
            elif [[ $response_ecraser == "n" ]]; then
                break
            else
                echo "Réponse invalide. Veuillez entrer 'o' (Oui) ou 'n' (Non)."
            fi
        done
    fi
fi


#Installation des dépendance
#echo "Mise a jour des dépendances"
#sudo apt update
#sudo apt install xrandr pactl xdotool wmctrl jq curl
