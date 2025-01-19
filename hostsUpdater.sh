#!/bin/bash

SEPARATOR="\t"

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
# Requête API pour trouver l'IP
REQUEST_API="http://ip-api.com/json/$URL"
NEW_IP=$(curl -s "$REQUEST_API" | jq -r '.query')

if ! [[ "$NEW_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo "Erreur de retour, impossible de trouver l'IP dans la réponse de l'API."
    exit 1
fi

echo "Adresse obtenue pour $URL : $NEW_IP"


# Vérifier si le domaine est présent dans /etc/hosts
if grep -qE "(\s|^)$URL(\s|$)" /etc/hosts; then
    # On remplace
    echo "Le domaine '$URL' est présent dans /etc/hosts. Remplacement..."
    sudo sed -i -E "s/^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(\s+)$URL(\s|$)/$NEW_IP\2$URL\3/" /etc/hosts
    echo "$URL mis à jour avec succès !"
else
    #On ajoute
    echo "Le domaine '$URL' n'est PAS présent dans /etc/hosts. Ajout..."

    # Vérifier si la ligne de commentaire # hostsUpdater existe
    if grep -q "^# hostsUpdater" /etc/hosts; then
        # On ajoute la nouvelle adresse IP du nouveau nom de domaine sous le commentaire # hostsUpdater
        sudo sed -i "/^# hostsUpdater/a $NEW_IP$SEPARATOR$URL" /etc/hosts
    else
        # On commente # hostsUpdater qui n'existe pas, et dessous on y ajoute la nouvelle adresse IP du nouveau nom de domaine
        echo -e "\n# hostsUpdater\n$NEW_IP$SEPARATOR$URL" | sudo tee -a /etc/hosts > /dev/null
    fi
    echo "$URL ajouté avec succès !"
fi