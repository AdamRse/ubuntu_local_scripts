if ! command -v wakeonlan &> /dev/null; then
    wout "Le paquet wakeonlan n'est pas installée, elle est nécéssaire au fonctionnement du script."
    if ask_yn "Installer le paquet wakeonlan ?"; then
        sudo apt update
        sudo apt install wakeonlan
    else
        eout "Installez wakeonlan pour lancer ce script."
    fi
fi