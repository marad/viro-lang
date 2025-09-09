.PHONY: shell

test:
	find spec -iname '*_spec.lua' | xargs -I {} -- bash -c "echo 'Running {}...' && ./lua {}"

repl:
	./lua viro/repl.lua
	
run:
	bin/viro

shell:
	nix develop
