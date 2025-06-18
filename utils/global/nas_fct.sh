#!/bin/bash

mount_nas() {
    echo -e "Paramètres :\n\
\$NAS_MOUNT_POINT=$NAS_MOUNT_POINT\n\
\$NAS_USER=$NAS_USER\n\
\$NAS_ADDR=$NAS_ADDR\n\
\$NAS_NAME=$NAS_NAME"
    
    if [ -z "$NAS_PASSWORD" ]; then
        echo "\$NAS_PASSWORD=<Empty>"
        echo "Ajouter un mot de passe, arrêt du script..."
        return 1
    else
        echo "\$NAS_PASSWORD=<OK>"
    fi

    echo "Création du point de montage dans $NAS_MOUNT_POINT"
    # Créer le point de montage local
    if ! mkdir -p "$NAS_MOUNT_POINT"; thencapt
        echo "Impossible de créer le point de montage."
        return 1
    fi
    echo "Point de montage créé"

    # Monter via SSHFS en utilisant SSH_ASKPASS
    export SSH_ASKPASS=/tmp/sshfs_askpass_$$
    echo "#!/bin/bash" > "$SSH_ASKPASS"
    echo "echo \"$NAS_PASSWORD\"" >> "$SSH_ASKPASS"
    chmod +x "$SSH_ASKPASS"
    
    echo "Tentative de montage du serveur NAS..."
    if setsid sshfs -o port="$NAS_PORT" -o reconnect -o ServerAliveInterval=15 -o ServerAliveCountMax=3 "$NAS_USER@$NAS_ADDR:/" "$NAS_MOUNT_POINT"; then
        echo "Montage réussi!"
        rm -f "$SSH_ASKPASS"
        echo "NAS monté sur $NAS_MOUNT_POINT. Contenu :"
        ls "$NAS_MOUNT_POINT"
    else
        echo "Impossible de monter le serveur NAS $NAS_NAME"
        rm -f "$SSH_ASKPASS"
        return 1
    fi
}