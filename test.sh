#!/bin/bash

USER="bakaarizon"
NAS_IP="home.adam.rousselle.me"
NAS_PORT="5022"  # Port SSH
REMOTE_PATH="/"
LOCAL_MOUNT="/mnt/nas_remote"

# Créer le point de montage local
mkdir -p "$LOCAL_MOUNT"

# Monter via SSHFS
sshfs -p $NAS_PORT $USER@$NAS_IP:$REMOTE_PATH $LOCAL_MOUNT -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3

echo "NAS monté sur $LOCAL_MOUNT"

if [ -z "$1" ]; then
fusermount -u /mnt/nas_remote
fi