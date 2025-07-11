.PHONY: generate test

generate:
	argbash -o devOpen.sh utils/argbash_templates/devOpen.template.m4

test: generate
	./devOpen.sh $(filter-out $@,$(MAKECMDGOALS))

%:  # Cette règle attrape toutes les cibles non définies
	@:  # Et ne fait rien avec