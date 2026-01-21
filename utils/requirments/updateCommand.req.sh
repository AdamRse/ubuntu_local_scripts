if ! command -v uuidgen &> /dev/null; then
    wout "La commande uuidgen n'est pas installée, elle est nécéssaire au fonctionnement du script."
    if ask_yn "Installer le package uuid-runtime ?"; then
        sudo apt update
        sudo apt install uuid-runtime
    else
        eout "Installez uuid-runtime pour lancer ce script."
    fi
fi