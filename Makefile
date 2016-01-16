SHELL=/bin/bash -o pipefail

NODE_MODULES := $(CURDIR)/node_modules

NPM_BIN := $(CURDIR)/node_modules/.bin

IMAGES = $(shell find content/assets/images -maxdepth 1 -iname '*.png')
STYLES = $(shell find content/assets/styles -iname '*.scss')

build: target/index.html target/CNAME

clean:
	rm -rf target

deploy: clean build
	rm -rf target/assets
	ghp-import -n -p -m "building site [skip ci]" target

assets: $(patsubst content/%,target/%,$(IMAGES)) target/assets/scripts/main.js target/assets/styles/main.css

target/index.html: content/index.html assets
	@mkdir -p $(dir $@)
	$(NPM_BIN)/html-inline -i content/index.html -o target/index.html -b target

target/assets/styles/main.css: $(STYLES)

target/assets/scripts/main.js: $(SCRIPTS)

target/assets/styles/%.css: content/assets/styles/%.css
	@mkdir -p $(dir $@)
	$(NPM_BIN)/postcss -u autoprefixer -u cssnano $< > $@

target/assets/scripts/%.js: content/assets/scripts/%.js
	@mkdir -p $(dir $@)
	$(NPM_BIN)/browserify $< | $(NPM_BIN)/uglifyjs --compress --output $@

target/%: content/%
	@mkdir -p $(dir $@)
	cp $< $@

.PHONY: build clean deploy