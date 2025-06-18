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
    if ! mkdir -p "$NAS_MOUNT_POINT"; then
        echo "Impossible de créer le point de montage."
        return 1
    fi
    echo "Point de montage créé"
    
    echo "Tentative de montage du serveur NAS..."
    if sshfs -o default_permissions,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,compression=yes,cache_timeout=3600 -p "$NAS_PORT" "$NAS_USER@$NAS_ADDR:/" "$NAS_MOUNT_POINT"; then
        echo "Montage réussi!"
    else
        echo "Impossible de monter le serveur NAS $NAS_NAME"
        return 1
    fi
}