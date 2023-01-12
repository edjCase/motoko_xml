# Overview

This is a library that extends on the Motoko base library for numbers. Maily focuses on encoding of numbers and 16/32 bit precision floats

# Package

### Vessel

Currently there is no official package but there is a manual process:

1. Add the following to the `additions` list in the `package-set.dhall`

```
{
    name = "xtended-numbers"
    , version = "{{Version}}"
    , repo = "https://github.com/gekctek/motoko_numbers"
    , dependencies = [] : List Text
}
```

Where `{{Version}}` should be replaced with the latest release from https://github.com/Gekctek/motoko_numbers/releases/

2. Add `xtended-numbers` as a value in the dependencies list
3. Run `make` which runs the vessel command to install the package

# API

# Library Devlopment:

## First time setup

To build the library, the `Vessel` library must be installed. It is used to pull down packages and locate the compiler for building.

https://github.com/dfinity/vessel

## Building

To build, run the `./build.sh` file. It will output wasm files to the `./build` directory

## Testing

To run tests, use the `./test.sh` file.
The entry point for all tests is `test/Tests.mo` file
It will compile the tests to a wasm file and then that file will be executed.
Currently there are no testing frameworks and testing will stop at the first broken test. It will then output the error to the console
