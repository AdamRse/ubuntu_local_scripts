#!/bin/bash

# On vérifie qu'on a reçu un paramètre et on le stock
if [[ -z "$1" ]]; then
    echo "Aucune url reçu en paramètre 1, abandon.";
    exit 1;
fi

# On enlève le https:// s'il est présent
URL=$(echo "$1" | sed -E 's|^(https?://)||')

# Vérifier si l'URL est bien un nom de domaine valide
if ! [[ "$URL" =~ ^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$ ]]; then
    echo "Le paramètre passé n'est pas un nom de domaine valide."
    exit 1
fi

echo "Identification effectuée, le nom de domaine '$URL' est conforme.";

# Vérifier si le domaine est présent dans /etc/hosts
if grep -qE "(\s|^)$URL(\s|$)" /etc/hosts; then
    echo "Le domaine '$URL' est présent dans /etc/hosts."
    sudo sed -i -E "s/^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(\s+)$URL(\s|$)/$NEW_IP\2$URL\3/" /etc/hosts
else
    echo "Le domaine '$URL' n'est PAS présent dans /etc/hosts."
fi