.PHONY: all

all: lint test

test:
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory lua/tests/automated/ { minimal_init = './scripts/minimal_init.vim' }"

fmt:
	stylua lua/ --config-path=.stylua.toml

lint:
	luacheck lua/greyjoy
