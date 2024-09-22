.PHONY: all

all: lint test

test:
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory lua/tests/automated/ { minimal_init = './scripts/minimal_init.vim' }"

fmt:
	stylua lua/ --config-path=.stylua.toml

deps:
	@mkdir -p deps
	git clone --depth 1 https://github.com/echasnovski/mini.nvim deps/mini.nvim

documentation:
	nvim --headless --noplugin -u ./scripts/minimal_init_doc.lua -c "lua require('mini.doc').generate()" -c "qa!"

documentation-ci: deps documentation

lint:
	luacheck lua/greyjoy
