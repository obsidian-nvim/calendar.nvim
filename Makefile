MINITEST = deps/mini.test
$(MINITEST):
	mkdir -p deps
	git clone --filter=blob:none https://github.com/echasnovski/mini.test $(MINITEST)

.PHONY: test
test: $(MINITEST)
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"
