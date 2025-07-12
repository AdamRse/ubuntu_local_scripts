.PHONY: generate devopen

generate:
	@argbash -o devOpen.sh utils/argbash_templates/devOpen.template.m4

devopen: generate
	@./devOpen.sh $(filter-out $@,$(MAKECMDGOALS))

%:  # Cette règle attrape toutes les cibles non définies
	@:  # Et ne fait rien avec