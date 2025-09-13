#!/bin/bash

mount_nas() {
    if [ -z "$NAS_USER" ] || [ -z "$NAS_ADDR" ] || [ -z "$NAS_NAME" ]; then
        echo "❌ Erreur : certaines variables NAS_* sont manquantes dans le .env"
        return 1
    fi
    if [ -z "$NAS_MOUNT_POINT" ]; then
        NAS_MOUNT_POINT="/mnt/$NAS_NAME"
    fi
    NAS_PORT=${NAS_PORT:-22}

    $debug && echo -e "Paramètres :\n\
\$NAS_MOUNT_POINT=$NAS_MOUNT_POINT\n\
\$NAS_USER=$NAS_USER\n\
\$NAS_ADDR=$NAS_ADDR\n\
\$NAS_PORT=$NAS_PORT\n\
\$NAS_NAME=$NAS_NAME"

    # Créer le dossier de montage
    sudo mkdir -p "$NAS_MOUNT_POINT"
    sudo chown $USER:$USER "$NAS_MOUNT_POINT"
    sudo chmod 774 "$NAS_MOUNT_POINT"

    # Vérifier si déjà monté
    if mount | grep -q "$NAS_MOUNT_POINT"; then
        echo "✅ NAS déjà monté sur $NAS_MOUNT_POINT"
        return 0
    fi

    echo "⏳ Montage du NAS..."

    # Lancer sshfs en arrière-plan, complètement détaché du terminal
    setsid sshfs -p "$NAS_PORT" \
        -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 \
        "$NAS_USER@$NAS_ADDR:/" "$NAS_MOUNT_POINT" \
        >/dev/null 2>&1 < /dev/null &

    sleep 1

    if mount | grep -q "$NAS_MOUNT_POINT"; then
        echo "✅ NAS monté sur $NAS_MOUNT_POINT"
    else
        echo "❌ Échec du montage"
        return 1
    fi
    return 0
}

unmount_nas() {
    if [ -z "$NAS_MOUNT_POINT" ]; then
        if [ -z "$NAS_NAME" ]; then
            echo "❌ Erreur : variable NAS_NAME manquante, impossible de déterminer le point de montage."
            return 1
        fi
        NAS_MOUNT_POINT="/mnt/$NAS_NAME"
    fi
    NAS_PORT=${NAS_PORT:-22}

    $debug && echo -e "Paramètres :\n\
\$NAS_MOUNT_POINT=$NAS_MOUNT_POINT\n\
\$NAS_NAME=$NAS_NAME"

    # Vérifier si le point de montage existe
    if mount | grep -q "$NAS_MOUNT_POINT"; then
        echo "⏳ Démontage du NAS..."
        fusermount -u "$NAS_MOUNT_POINT" 2>/dev/null || sudo umount "$NAS_MOUNT_POINT"

        sleep 1

        if mount | grep -q "$NAS_MOUNT_POINT"; then
            echo "❌ Échec du démontage"
            return 1
        else
            echo "✅ NAS démonté de $NAS_MOUNT_POINT"
            return 0
        fi
    else
        echo "ℹ️ Aucun NAS monté sur $NAS_MOUNT_POINT"
        return 0
    fi
}
