> [!WARNING]
> Compatibilité Linux seulement
# REQUIREMENTS

## toggleScreens.sh
Pour basculer l'allumage des écrans quand c'est nécéssaire (mode jeu, mode travail).
A configurer.
### Installation
- xrandr (generally already installed)
- pactl (generally already installed)
```bash
sudo apt install xrandr pactl
```
## travail.sh (Obsolète)
Permet d'ouvrir l'environement de travail. C'est un projet archivé qui devra être reparamétré pour permettre l'utilisation sur plusieurs projets.
### Installation
- xdotools
- wmctrl
```bash
sudo apt install xdotool wmctrl
```
## hostsUpdater.sh
Permet de mettre à jour le fichier /etc/hosts pour un nom de domaine qui aurait changé d'IP.
### Installation
- jq
- curl
```bash
sudo apt install jq curl
```
## laravelGetContextFiles.sh
Pour collecter les fichiers source importants d'un projet, et les copier dans un dossier de contexte pour un LLM. Permet aussi d'ajouter des instructions et un contexte.
### Installation
- jq
```bash
sudo apt install jq
```
### Utilisation
Créer un dossier ```.contexte/``` à la racine du projet pour y ajouter toutes les instructions et le contexte supplémentaire aux projet.  
Par exemple, pour ajouter des collections postman au contexte, on peut le faire dans ```.context/postman_collections/collection1.json```.
> [!NOTE]
> Chaque fichier copié dans le dossier de contexte ajoute un commentaire en promière ligne signifiant le répertoire du fichier dans le projet.

Pour préciser quels fichiers ajouter au dossier de contexte, ajouter un fichier json ```.context/context-config.json``` de la forme "glob pattern" suivante :
```js
{
  "files_to_collect": [
    "app/Models/**/*.php",
    "app/Http/Controllers/**/*.php",
    "app/Http/Middleware/**/*.php",
    "database/migrations/**/*.php",
    "routes/api.php",
    "routes/web.php",
    "config/**/*.php",
    ".context/**/*"
  ],
  "files_to_ignore": [ # optionel
    "database/migrations/*cache_table.php",
    "app/Http/Controllers/Controller.php",
    "resources/views/components/**/*"
  ],
  "copy_location": "$HOME/Téléchargements/Contexte_LLM" # optionel
}
```
> [!WARNING]
>  ```"files_to_ignore"``` est prioritaire sur ```"files_to_collect"```

> [!NOTE]
> Le fichier ```context-config.json``` est conseillé, mais optionnel.

## sleepWhenDone.sh
Met l'ordinateur en veille lorsqu'un fichier atteint la taille voulue
### Installation
Aucune installation
### Utilisation
Mosifier les variables
- ```nomFichier``` : Le nom et chemin du fichier ciblé
- ```valeurComparaison``` : Taille du fichier en octet qui déclenche la veille
- ```attenteTampon``` : Temps d'attente en secondes pour déclencher la mise en veille une fois le poids du fichier atteint

## Installation complète
```bash
sudo apt install xrandr pactl xdotool wmctrl jq curl
```

