#!/bin/bash

mount_nas() {
# Vérifier si les variables nécessaires sont définies
    if [ -z "$NAS_NAME" ] || [ -z "$NAS_USER" ] || [ -z "$NAS_ADDR" ]; then
        echo "Erreur: Les variables NAS_NAME, NAS_USER et NAS_ADDR doivent être définies"
        return 1
    fi

    NAS_MOUNT_POINT="/mnt/$NAS_NAME"
    NAS_PORT=${NAS_PORT:-22}  # Port SSH par défaut
    
    echo -e "Paramètres :\n\
\$NAS_MOUNT_POINT=$NAS_MOUNT_POINT\n\
\$NAS_USER=$NAS_USER\n\
\$NAS_ADDR=$NAS_ADDR\n\
\$NAS_PORT=$NAS_PORT\n\
\$NAS_NAME=$NAS_NAME"

    # Récupération du mot de passe depuis le trousseau de clés
    local keyring_entry="nas-$NAS_NAME-password"
    
    if [ -z "$NAS_PASSWORD" ]; then
        echo "Mot de passe non trouvé dans le trousseau de clés."
        read -rsp "Entrez le mot de passe pour $NAS_NAME: " NAS_PASSWORD
        echo
        
    else
        echo "Mot de passe récupéré depuis le .env"
    fi

    # Création du point de montage
    echo "Création du point de montage dans $NAS_MOUNT_POINT"
    if ! sudo mkdir -p "$NAS_MOUNT_POINT"; then
        echo "Impossible de créer le point de montage."
        return 1
    fi
    sudo chown adam:adam "$NAS_MOUNT_POINT"
    echo "Point de montage créé"

    # Montage avec SSHFS
    echo "Tentative de montage du serveur NAS..."
    if ! which sshpass >/dev/null; then
        echo "Installation de sshpass nécessaire pour l'automatisation"
        sudo apt-get install -y sshpass
    fi

    if sshpass -p "$NAS_PASSWORD" sshfs -o \
        allow_other,default_permissions,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,compression=yes,cache_timeout=3600,password_stdin -p "$NAS_PORT" "$NAS_USER@$NAS_ADDR:/" "$NAS_MOUNT_POINT" <<<"$NAS_PASSWORD"; then
        echo "Montage réussi!"
    else
        echo "Échec du montage du serveur NAS $NAS_NAME"
        return 1
    fi

    return 0
}

unmount_nas() {
    if [ -z "$NAS_NAME" ]; then
        echo "Erreur: NAS_NAME doit être défini"
        return 1
    fi

    NAS_MOUNT_POINT="/mnt/$NAS_NAME"
    
    if fusermount -u "$NAS_MOUNT_POINT"; then
        echo "Démontage réussi de $NAS_MOUNT_POINT"
        sudo rmdir "$NAS_MOUNT_POINT"
    else
        echo -e "Échec du démontage de $NAS_MOUNT_POINT.\nVérifier si un processus est en cours d'utilisation"
        return 1
    fi
}