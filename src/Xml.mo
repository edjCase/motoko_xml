import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Tokenizer "Tokenizer";
import Parser "Parser";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";

module {

    public type DecodeDocumentError = Parser.ParseError or {
        #tokenizeError : Text;
    };

    public type DecodeError = DecodeDocumentError or {
        #rootElementError : Types.RootElementError;
    };

    public type DecodeResult = {
        #ok : Types.RootElement;
        #error : DecodeError;
    };

    public type DecodeDocumentResult = {
        #ok : Types.Document;
        #error : DecodeDocumentError;
    };

    public func decode(bytes : Blob) : DecodeResult {
        let document = switch (decodeDocument(bytes)) {
            case (#error(e)) return #error(e);
            case (#ok(d)) d;
        };
        return #ok(document);
    };

    public func decodeDocument(bytes : Blob) : DecodeDocumentResult {
        let tokens : [Types.Token] = switch (Tokenizer.tokenizeBlob(bytes)) {
            case (#error(e)) return #error(#tokenizeError(e));
            case (#ok(t)) t;
        };
        return Parser.parseDocument(Iter.fromArray(tokens));
    };

    private func decodeTextValue(buffer : Buffer.Buffer<Char>) : Result<Text> {
        let decodedTexcharBuffer = Buffer.Buffer<Char>(buffer.size());
        let referenceValueBuffer = Buffer.Buffer<Char>(4);
        var inAmp = false;
        for (c in buffer.vals()) {
            // If characters are between & and ; then they are a reference
            // to a value. This does the translation if it can
            if (inAmp) {
                if (c == ';') {
                    inAmp := false;
                    // Decode the value and write it to the text buffer
                    switch (writeEntityValue(referenceValueBuffer, decodedTexcharBuffer)) {
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

    private func writeEntityValue(escapedValue : Buffer.Buffer<Char>, decodedTexcharBuffer : Buffer.Buffer<Char>) : Result<()> {
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
            case ('%') {
                Prelude.nyi(); // TODO parameters?
            };
            case (_) {
                let c = switch (Text.fromIter(escapedValue.vals())) {
                    case ("lt") '<';
                    case ("gt") '>';
                    case ("apos") '\'';
                    case ("quot") '\"';
                    case ("amp") '&';
                    case (entityId) {
                        // TODO custom entities. This just returns the original value
                        decodedTexcharBuffer.add('&');
                        decodedTexcharBuffer.append(escapedValue);
                        decodedTexcharBuffer.add(';');
                        return #ok;
                    };
                };
                decodedTexcharBuffer.add(c);
                #ok;
            };
        };
    };

};
