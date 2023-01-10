#!/usr/bin/env bash

set -e # Fail script on any errors

dir=build
if [[ ! -e $dir ]]; then
    mkdir -p $dir
fi
$(mops bin)/moc $(mops sources) -wasi-system-api test/Tests.mo -o $dir/Test.wasm

wasmtime $dir/Test.wasm