import Document "Document";
import Element "Element";
import TrieMap "mo:base/TrieMap";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import NatX "mo:xtended-numbers/NatX";
import Iter "mo:base/Iter";
import Char "mo:base/Char";
import Nat32 "mo:base/Nat32";
module {
    type Result<T> = { #ok : T; #error : Text };

    public func processDocument(document : Document.Document) : Result<Element.Element> {
        let defaultEntries = Iter.fromArray([
            ("amp", "&"),
            ("apos", "'"),
            ("gt", ">"),
            ("lt", "<"),
            ("quot", "\""),
        ]);
        let entityMap = TrieMap.fromEntries<Text, Text>(defaultEntries, Text.equal, Text.hash);
        addEntities(document.docType, entityMap);
        processElement(document.root, entityMap);
    };

    private func addEntities(docType : ?Document.DocType, entityMap : TrieMap.TrieMap<Text, Text>) {
        switch (docType) {
            case (null)();
            case (?d) {
                let paramerterEntityMap = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);
                // Add any parameter entities first, to potentially replace the entity values
                for (internalType in Iter.fromArray(d.typeDefinition.internalTypes)) {
                    switch (internalType) {
                        case (#parameterEntity({ name = n; type_ = #internal(v) })) {
                            paramerterEntityMap.put(("%" # n, v));
                        };
                        case (_)();
                    };
                };
                // Add any general entity values
                for (internalType in Iter.fromArray(d.typeDefinition.internalTypes)) {
                    switch (internalType) {
                        case (#generalEntity({ name = n; type_ = #internal(v) })) {
                            let realV = switch (paramerterEntityMap.get(v)) {
                                case (null) v; // If not found, use the value as is
                                case (?parameterV) parameterV; // Replace with parameter value
                            };
                            entityMap.put((n, realV));
                        };
                        case (_)();
                    };
                };
            };
        };
    };

    private func processElement(element : Document.Element, entityMap : TrieMap.TrieMap<Text, Text>) : Result<Element.Element> {
        let children : Element.ElementChildren = switch (element.children) {
            case (#open(children)) {
                let childrenBuffer = Buffer.Buffer<Element.ElementChild>(children.size());
                for (child in Iter.fromArray(children)) {
                    switch (processElementChild(child, entityMap)) {
                        case (#error(e)) return #error(e);
                        case (#ok(null))(); // Skip (comments)
                        case (#ok(?c)) childrenBuffer.add(c);
                    };
                };
                #open(Buffer.toArray(childrenBuffer));
            };
            case (#selfClosing) #selfClosing;
        };

        #ok({
            name = element.name;
            attributes = element.attributes;
            children = children;
        });
    };

    private func processElementChild(
        child : Document.ElementChild,
        entityMap : TrieMap.TrieMap<Text, Text>,
    ) : Result<?Element.ElementChild> {
        let processedChild = switch (child) {
            case (#element(e)) {
                switch (processElement(e, entityMap)) {
                    case (#error(e)) return #error(e);
                    case (#ok(e)) ?#element(e);
                };
            };
            case (#text(t)) {
                switch (processText(t, entityMap)) {
                    case (#error(e)) return #error(e);
                    case (#ok(t)) ?#text(t);
                };
            };
            case (#comment(c)) null;
            case (#cdata(c)) ?#text(c); // Dont process CDATA
        };
        #ok(processedChild);
    };

    private func processText(text : Text, entityMap : TrieMap.TrieMap<Text, Text>) : Result<Text> {
        let decodedTexcharBuffer = Buffer.Buffer<Char>(text.size());
        let referenceValueBuffer = Buffer.Buffer<Char>(4);
        var inAmp = false;
        for (c in text.chars()) {
            // If characters are between & and ; then they are a reference
            // to a value. This does the translation if it can
            if (inAmp) {
                if (c == ';') {
                    inAmp := false;
                    // Decode the value and write it to the text buffer
                    switch (writeEntityValue(referenceValueBuffer, decodedTexcharBuffer, entityMap)) {
                        case (#ok)();
                        case (#error(e)) return #error(e);
                    };
                    // Clear character buffer and continue iterating
                    referenceValueBuffer.clear();
                } else {
                    // Add to the character buffer if between & and ;
                    referenceValueBuffer.add(c);
                };
            } else {
                if (c == '&') {
                    inAmp := true;
                } else {
                    // Add regular character
                    decodedTexcharBuffer.add(c);
                };
            };
        };
        if (inAmp) {
            return #error("Unexpected character '&'");
        };
        #ok(Text.fromIter(decodedTexcharBuffer.vals()));
    };

    private func writeEntityValue(
        escapedValue : Buffer.Buffer<Char>,
        decodedTexcharBuffer : Buffer.Buffer<Char>,
        entityMap : TrieMap.TrieMap<Text, Text>,
    ) : Result<()> {
        // If starts with a #, its a unicode character
        switch (escapedValue.get(0)) {
            case ('#') {
                // # means its a unicode value
                let unicodeScalar : ?Nat = if (escapedValue.get(1) == 'x') {
                    // If prefixed with x, it is a hex value
                    let hexBuffer = Buffer.subBuffer<Char>(escapedValue, 2, escapedValue.size() - 2);
                    let hex = Text.fromIter(hexBuffer.vals());
                    NatX.fromTextAdvanced(hex, #hexadecimal, null); // Parse hexadecimal
                } else {
                    // Otherwise its a decimal value
                    let decimalBuffer = Buffer.subBuffer<Char>(escapedValue, 1, escapedValue.size() - 1);
                    let decimal = Text.fromIter(decimalBuffer.vals());
                    NatX.fromText(decimal); // Parse decimal
                };
                switch (unicodeScalar) {
                    case (null) return #error("Invalid unicode value '" # Text.fromIter(escapedValue.vals()) # "'");
                    case (?s) {
                        // Must fit in a nat32
                        if (s > 4294967295) {
                            return #error("Invalid unicode value '" # Text.fromIter(escapedValue.vals()) # "'");
                        };
                        // Convert unicode id to a unicode character
                        let unicodeCharacter = Char.fromNat32(Nat32.fromNat(s));
                        decodedTexcharBuffer.add(unicodeCharacter);
                        #ok;
                    };
                };
            };
            case (_) {
                switch (entityMap.get(Text.fromIter(escapedValue.vals()))) {
                    case (null) {
                        // Could not find the entity. This just returns the original value
                        decodedTexcharBuffer.add('&');
                        decodedTexcharBuffer.append(escapedValue);
                        decodedTexcharBuffer.add(';');
                    };
                    case (?replacement) {
                        for (c in replacement.chars()) {
                            decodedTexcharBuffer.add(c);
                        };
                    };
                };
                #ok;
            };
        };
    };

};
