#!/bin/bash
HOME="/home/oem"
DIR_DEFAULT="$HOME/dev"

if [[ -z "$1" ]]; then
    echo "Aucun nom de projet reçu en paramètre 1, abandon.";
    exit 1;
fi

DIR_LOC="$DIR_DEFAULT/$1"

if [ -d "$DIR_LOC" ]; then
    echo "Le répertoire '$DIR_LOC' existe déjà, abandon.";
    exit 1;
fi

if [[ -z "$2" ]]; then
    URL="$1.loc"
    echo "Aucun nom d'url spécifique passé en paramètre 2, le nom choisi sera donc '$URL'";
else
    URL=$2
fi

mkdir $DIR_LOC && echo "Création du répertoire"
sudo sed -i "1a 127.0.0.1\t${URL}" /etc/hosts && echo "Ajout du DNS local"

sudo cat << EOF > /etc/apache2/sites-available/$1.conf
<VirtualHost *:80>
    ServerName ${URL}
    ServerAdmin webmaster@localhost
    DocumentRoot ${DIR_LOC}
    <Directory ${DIR_LOC}>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/${1}_error.log
    CustomLog \${APACHE_LOG_DIR}/${1}_access.log combined
</VirtualHost>
EOF

echo "Écriture du fichier de configuration";
sudo a2ensite $1
sudo systemctl reload apache2
echo "Mise à jour d'apache 2";
sudo -u $SUDO_USER code $DIR_LOC
exit 0;