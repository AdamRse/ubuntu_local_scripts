# Développement en cours
## Workflow
- Pour développer et tester les scipts, écrire le code dans ```utils/argbash_templates/```
- Les liens doivent faire référence à la racine
- Ajouter le script au makefile
    - compilation : argbash -o ```<NomScript>```.sh utils/argbash_templates/```<NomScript>```.template.m4
    - execution : ./devOpen.sh $(filter-out $@,$(MAKECMDGOALS))
        - permet l'execution du script avec des paramètres personnalisés
    - options : ```%: @:```
        - permet de prendre en compte des paramètres en plus sans être interété par le makefile, mais par le script testé.
- execute le Makefile : ```make <nomScript> [paramètres]```
### Exemple
Makefile :
```Makefile
# Exemple du makefile pour tester devopen.sh avec la commande : make devopen
.PHONY: generate devopen

generate:
	@argbash -o devOpen.sh utils/argbash_templates/devOpen.template.m4

devopen: generate
	@./devOpen.sh $(filter-out $@,$(MAKECMDGOALS))

%:  # Attraper toutes les cibles non définies
	@:  # Et ne rien faire avec, elles seront executées en paramètre de devopen.sh
```
> [!NOTE]
> le ```@``` qui précède les commandes permettent de supprimer l'apparition des lignes executées dans le makefile. La sortie de ```@./devOpen.sh``` reste affichée.
---
Commandes bash à la racine du projet :
```bash
# Compiler et executer le script devopen.sh
make devopen
# Utiliser des paramètre personnalisés pour devopen.sh
make devopen paramètre1 paramètre2

```