SOURCES=$(shell mops sources)
MOC=$(shell vessel bin)/moc


.PHONY: all
all: test Xml.wasm

test: Xml.wasm Test.wasm
	wasmtime ./build/Test.wasm

Test.wasm:
	$(MOC) $(SOURCES) -wasi-system-api test/Tests.mo -o ./build/Test.wasm

Xml.wasm:
	$(MOC) $(SOURCES) -wasi-system-api "./src/Xml.mo" -o ./build/Xml.wasm

mops:
	npm install

.PHONY: clean
clean:
	rm -r ./build/*