SOURCES=$(shell mops sources)
MOC=$(shell vessel bin)/moc
BUILD=build
COMPILE_MO=$(MOC) $(SOURCES) -wasi-system-api $< -o $@



.PHONY: all
all: test $(BUILD)/Xml.wasm

test: $(BUILD)/Tests.wasm
	wasmtime ./build/Tests.wasm

$(BUILD)/Tests.wasm: test/Tests.mo make_build_dir
	$(COMPILE_MO)

$(BUILD)/Xml.wasm: src/Xml.mo make_build_dir
	$(COMPILE_MO)

make_build_dir:
	mkdir -p $(BUILD)

.PHONY: clean
clean:
	rm -r ./build/*