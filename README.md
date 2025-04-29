# Funding

This library was originally incentivized by ICDevs. You can view more about the bounty on the forum or website. The bounty was funded by The ICDevs.org commuity and the award paid to @Gekctek. If you use this library and gain value from it, please consider a donation to ICDevs.

# Overview

This is a library that handles XML serialization and deserialization with UTF8 bytes and text

# Package installation

## MOPS

### CLI

Run `mops add xml`

### Or manually:

Modify the `mops.toml` file to add:

```
[dependencies]
xml = "{version}"
```

where `{version}` is the version number you want to use

See detailed MOPS documentation [here](https://mops.one/docs/install)

# Usage

```motoko
import Xml "mo:xml"
...

let element : Xml.Element = {
    name = "root";
    attributes = [{ name = "attr1"; value=?"value1" }];
    children = #open([
        {
            name = "br";
            attributes = [];
            children = #selfClosing;
        }
    ])
}
// To/from text

let serializedXml : Text = Xml.toText(element); // <root attr1="value1"><br/></root>

let xmlObj : Xml.Element = Xml.fromText("<root attr1=\"value1\"><br/></root>".chars())

// OR to/from bytes

let xmlBytes : Iter.Iter<Nat8> = Xml.toBytes(element);

let xmlObj2 : Xml.Element = Xml.fromBytes(xmlBytes);
```

# First time setup

To build the library, the `MOPS` library must be installed. It is used to pull down packages and running tests.

MOPS install instructions: https://mops.one/docs/install

# Testing

To run tests, use the `make test` command or run manually with `mops test`.
The tests use MOPS test framework
