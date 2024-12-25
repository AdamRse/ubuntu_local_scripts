#!/bin/bash
DIR_HOME_DEFAULT="dev"
# Vérifie si le script est lancé avec sudo
if [ "$(id -u)" -ne 0 ]; then
    SUDO_HOME="$HOME"
    USER_GROUP=$(id -gn "$USER")
  else
    SUDO_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    USER_GROUP=$(id -gn "$SUDO_USER")
fi
DIR_DEFAULT="$SUDO_HOME/$DIR_HOME_DEFAULT"


# Vérification de la présence du permier paramètre (nom du site)
if [[ -z "$1" ]]; then
    echo "Aucun nom de projet reçu en paramètre 1, abandon.";
    exit 1;
fi

# Déclaration de la variable de l'emplacement du site
DIR_LOC="$DIR_DEFAULT/$1"

# On vérifie que le site n'est pas déjà créé
if [ -d "$DIR_LOC" ]; then
    echo "Le répertoire '$DIR_LOC' existe déjà, abandon.";
    exit 1;
fi

# On détermine l'url locale avec $2 ou une variable par défaut
if [[ -z "$2" ]]; then
    URL="$1.loc"
    echo "Aucun nom d'url spécifique passé en paramètre 2, le nom choisi sera donc '$URL'";
else
    URL=$2
fi

# Vérification du droit d'accès de www-data
if sudo -u www-data ls ~/ &>/dev/null; then
  echo "Vérification de l'accès de www-data à ~/."
else
  echo "www-data n'a pas accès à ~/."
  echo "Ajout du groupe $USER_GROUP à www-data..."
  
  # Ajout du groupe de l'utilisateur à www-data
  usermod -aG "$USER_GROUP" www-data

  if [ $? -eq 0 ]; then
    echo "Groupe $USER_GROUP ajouté à www-data avec succès."
  else
    echo "Échec de l'ajout du groupe. Veuillez vérifier vos permissions."
    exit 2
  fi
fi



mkdir $DIR_LOC && echo "Création du répertoire"
sudo chown $SUDO_USER:www-data $DIR_LOC
sudo chmod 771 $DIR_LOC && echo "Attribution des droits"
sudo sed -i "1a 127.0.0.1\t${URL}" "/etc/hosts" && echo "Ajout du DNS local"

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