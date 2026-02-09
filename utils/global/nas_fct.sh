#!/bin/bash

mount_nas() {
    local nas_port=${NAS_PORT:-22}
    local nas_mount_point="$(clean_path_variable "absolute" "${NAS_MOUNT_POINT}")"
    local timeout_sec=${NAS_TIMEOUT_SEC:-15}
    [ -z "${NAS_USER}" ] && eout "Variable 'NAS_USER' manquante dans le .env (Nom d'utilisateur pour se connecter au NAS)"
    [ -z "${NAS_ADDR}" ] && eout "Variable 'NAS_ADDR'manquante dans le .env (Adresse IP ou nom de domaine du NAS)"
    [ -z "${NAS_NAME}" ] && eout "Variable 'NAS_NAME' manquante dans le .env (Nom du NAS)"
    [ -z "${NAS_MAC_ADDR}" ] && eout "Variable 'NAS_MAC_ADDR' manquante dans le .env (adresse mac de l'interface réseau)"
    [ -z "${NAS_MOUNT_POINT}" ] && eout "Variable 'NAS_MOUNT_POINT' manquante dans le .env (Répertoire utilisateur dans lequel créer le point de montage)"
    [ -z "${NAS_TIMEOUT_SEC}" ] && wout "Variable 'NAS_TIMEOUT_SEC' manquante dans le .env (Temps de démarrage du NAS avec marge de sécurité). timeout par défaut : ${timeout_sec} secondes."
    [ -z "${NAS_PORT}" ] && wout "Variable 'NAS_PORT' manquante dans le .env (Numéro de port pour se connecter en SSH). Port par défaut : ${nas_port}."

    debug_ "Paramètres :
    - \$nas_mount_point=$nas_mount_point
    - \$NAS_USER=$NAS_USER
    - \$NAS_ADDR=$NAS_ADDR
    - \$nas_port=$nas_port
    - \$NAS_NAME=$NAS_NAME"

    is_nas_mounted "${nas_mount_point}" && lout "NAS déjà monté sur ${nas_mount_point}" && return 0
    ! is_empty_dir "${nas_mount_point}" && fout "Le point de montage '${nas_mount_point}' n'est pas vide. Il semblerait que ce ne soit pas le NAS qui soit monté à cet endroit. Avandon..." && return 1
    mkdir -p "${nas_mount_point}" && fout "Impossible de monter le serveru NAS sur '${nas_mount_point}', permission refusée." && return 1
    wake_and_wait_ping "${timeout_sec}" && fout "Le NAS ne répond pas à l'adresse ${NAS_ADDR} donnée." && return 1
    
    # Le NAS est en ligne, mais pas forcément disponible immédiatement (sortie de veille, ou allumage)
    lout "⏳ Montage de ${NAS_NAME}..."
    if sshfs "${NAS_USER}@${NAS_ADDR}:/" -p "${NAS_PORT}" "${nas_mount_point}" -o Ciphers=aes128-ctr,compression=no,reconnect; then
        sout "${NAS_NAME} monté dans ${nas_mount_point}"
        return 0
    else
        fout "Impossible de monter ${NAS_NAME}, sshfs retourne une erreur."
        return 1
    fi
}

# $1 : nas_mount_point  : chemin absolu du point de montage du nas
# return bool
is_nas_mounted() {
    local nas_mount_point="${1}"
    [ -z "${nas_mount_point}" ] && eout "is_nas_mounted() : Aucun argument passé, chemin absolu du point de montage attentu."
    [ -d "${nas_mount_point}" ] || eout "is_nas_mounted() : Mauvais argument, aucun répertoire trouvé dans '${nas_mount_point}'. Vérifiez l'argument passé ou les droits du répertoire."
    mountpoint -q "${nas_mount_point}"
}

# $1 : timout_sec   : Nombre de secondes nécéssaires au NAS pour qu'il démarre et réponde
# return bool
wake_and_wait_ping() {
    local timout_sec=${1:-10}
    local mac_addr="${NAS_MAC_ADDR}"
    local ip="${NAS_ADDR}"
    local regex_ip="^[1-9][0-9]{0,2}\.[1-9][0-9]{0,2}\.[1-9][0-9]{0,2}\.[1-9][0-9]{0,2}$"
    local regex_mac="^([0-9a-fA-F]{2}[:\-]){5}[0-9a-fA-F]{2}$"
    local request="${mac_addr}"
    [ -z "${timout_sec}" ] && wout "wake_and_wait_ping() : aucun timeout donné, le timeout par défaut est fixé à ${timout_sec} secondes"
    [ -z "${NAS_MAC_ADDR}" ] && eout "Variable 'NAS_MAC_ADDR' manquante dans le .env (adresse mac de l'interface réseau)"
    [[ $mac_addr =~ $regex_mac ]] || eout "La variable 'NAS_MAC_ADDR' dans le .env n'est pas une adresse mac valide"
    [[ $timout_sec =~ ^[0-9]+$ ]] || eout "wake_and_wait_ping() : Le paramètre 'timout_sec' passé à la fonction en premier paramètre n'est pas un nombre : '${timout_sec}'"

    if ping -c 1 -W 1 "${ip}" > /dev/null 2>&1; then
        lout "Le NAS est en ligne"
        return 0
    fi

    if [[ $ip =~ $regex_ip ]]; then
        request="-i ${ip} ${request}"
    fi
    debug_ "Requête de réveil du NAS"
    wakeonlan ${request}

    debug_ "Attente du PING du NAS"
    local waited_sec=0
    while [ $waited_sec -lt $timout_sec ]; do
        if ping -c 1 -W 1 "${ip}" > /dev/null 2>&1; then
            echo ""
            lout "Le NAS est en ligne"
            return 0
        fi
        ((waited_sec++))
        echo -n "~"
    done
    echo ""
    fout "Le NAS n'a pas répondu après ${timout_sec} secondes."
    return 1
}
unmount_nas() {
    local nas_mount_point="$(clean_path_variable "absolute" "${NAS_MOUNT_POINT}")"
    [ -z "${NAS_NAME}" ] && eout "Variable 'NAS_NAME' manquante dans le .env (Nom du NAS)"
    [ -z "${NAS_MOUNT_POINT}" ] && eout "Variable 'NAS_MOUNT_POINT' manquante dans le .env (Répertoire utilisateur dans lequel créer le point de montage)"
    [ -d "${NAS_MOUNT_POINT}" ] || eout "Le point de montage spécifié dans le .env 'NAS_MOUNT_POINT' n'existe pas ou n'est pas accessible."

    debug_ "Paramètres :
    \$nas_mount_point=${nas_mount_point}
    \$NAS_NAME=${NAS_NAME}"

    # Vérifier si le point de montage existe
    if is_nas_mounted "${nas_mount_point}"; then
        lout "⏳ Démontage de ${NAS_NAME}..."
        fusermount -u "${nas_mount_point}" 2>/dev/null || sudo umount "${nas_mount_point}"
        is_nas_mounted "${nas_mount_point}" && {
            fout "Échec du démontage"
            return 1
        }
        sout "NAS démonté de ${nas_mount_point}"
        return 0
    else
        lout "Aucun NAS monté sur ${nas_mount_point}"
        return 0
    fi
}
