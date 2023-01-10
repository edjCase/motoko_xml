BUILD=build
COMPILE_MO=$(shell vessel bin)/moc $(shell mops sources) -wasi-system-api $< -o $@



.PHONY: all
all: test $(BUILD)/Xml.wasm

test: $(BUILD)/Tests.wasm
	wasmtime ./build/Tests.wasm

$(BUILD)/Tests.wasm: test/Tests.mo make_build_dir install_mops_sources
	$(COMPILE_MO)

$(BUILD)/Xml.wasm: src/Xml.mo make_build_dir install_mops_sources
	$(COMPILE_MO)

install_mops_sources:
	mops install

make_build_dir:
	mkdir -p $(BUILD)

.PHONY: clean
clean:
	rm -r ./build/*