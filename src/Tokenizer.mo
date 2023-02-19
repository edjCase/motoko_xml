import Utf8 "Utf8";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Char "mo:base/Char";
import Types "Types";
import Nat "mo:base/Nat";
import NatX "mo:xtended-numbers/NatX";
import Prelude "mo:base/Prelude";
import Array "mo:base/Array";
import Nat32 "mo:base/Nat32";

// TODO escape & < > ' "
// TODO <![CDATA[ ]]> escapes whats inside

module {

    public let UNEXPECTED_ERROR_MESSAGE = "Unexpected end of characters";

    type Result<T> = { #ok : T; #error : Text };

    public type TokenizeResult = Result<[Types.Token]>;

    public func tokenizeText(value : Text) : TokenizeResult {
        let reader = Utf8.Reader(Text.toIter(value));
        return tokenize(reader);
    };

    public func tokenizeBlob(value : Blob) : TokenizeResult {
        let reader = Utf8.Reader(Utf8.Utf8Iter(value.vals()));
        return tokenize(reader);
    };

    public func tokenizeBytes(value : [Nat8]) : TokenizeResult {
        let reader = Utf8.Reader(Utf8.Utf8Iter(value.vals()));
        return tokenize(reader);
    };

    public func tokenize(reader : Utf8.Reader) : TokenizeResult {
        let tokenBuffer = Buffer.Buffer<Types.Token>(2);
        loop {
            switch (getNext(reader)) {
                case (#ok(t)) {
                    tokenBuffer.add(t);
                };
                case (#end) return #ok(Buffer.toArray(tokenBuffer));
                case (#error(e)) return #error(e);
            };
        };
    };

    private func getNext(reader : Utf8.Reader) : Result<Types.Token> or { #end } {
        reader.skipWhitespace();
        let charBuffer = Buffer.Buffer<Char>(0);
        loop {
            switch (reader.peek()) {
                case (null) {
                    // If next is null, then its the end
                    let _ = reader.next();
                    return #end;
                };
                case (?c) {
                    // If next is '<', then parse out the tag
                    // or return the text value that has built up
                    if (c == '<') {
                        let token = if (charBuffer.size() > 0) {
                            let textValue = switch (decodeTextValue(charBuffer)) {
                                case (#error(e)) return #error(e);
                                case (#ok(v)) v;
                            };
                            #text(textValue);
                        } else {
                            switch (parseTagToken(reader)) {
                                case (#error(e)) return #error(e);
                                case (#ok(t)) t;
                            };
                        };
                        return #ok(token);
                    } else {
                        switch (c) {
                            // < and > are only allowed in the context of tags
                            // must be escaped for text
                            case ('>') return #error("Unexpected character '>'");
                            case (_)(); // Skip
                        };
                        charBuffer.add(c);
                        let _ = reader.next();
                    };
                };
            };
        };
    };

    private func decodeTextValue(buffer : Buffer.Buffer<Char>) : Result<Text> {
        let decodedTextBuffer = Buffer.Buffer<Char>(buffer.size());
        let referenceValueBuffer = Buffer.Buffer<Char>(4);
        var inAmp = false;
        for (c in buffer.vals()) {
            // If characters are between & and ; then they are a reference
            // to a value. This does the translation if it can
            if (inAmp) {
                if (c == ';') {
                    inAmp := false;
                    // Decode the value and write it to the text buffer
                    switch (writeEntityValue(referenceValueBuffer, decodedTextBuffer)) {
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
                    decodedTextBuffer.add(c);
                };
            };
        };
        if (inAmp) {
            return #error("Unexpected character '&'");
        };
        #ok(Text.fromIter(decodedTextBuffer.vals()));
    };

    private func writeEntityValue(escapedValue : Buffer.Buffer<Char>, decodedTextBuffer : Buffer.Buffer<Char>) : Result<()> {
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
                        decodedTextBuffer.add(unicodeCharacter);
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
                    case ("quot") '\u{22}';
                    case (entityId) {
                        // TODO custom entities. This just returns the original value
                        decodedTextBuffer.add('&');
                        decodedTextBuffer.append(escapedValue);
                        decodedTextBuffer.add(';');
                        return #ok;
                    };
                };
                decodedTextBuffer.add(c);
                #ok;
            };
        };
    };

    private func getTagInfo(t : Text) : Result<Types.TagInfo> {
        let tagTokens : Iter.Iter<Result<Text>> = TagTokenIterator(t);

        let name : Text = switch (tagTokens.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (?t) switch (t) {
                case (#error(e)) return #error(e);
                case (#ok(t)) t;
            };
        };

        let attributes = Buffer.Buffer<Types.Attribute>(0);

        label l loop {
            let attribute = switch (tagTokens.next()) {
                case (null) {
                    break l;
                };
                case (?#error(e)) {
                    return #error(e);
                };
                case (?#ok(t)) {
                    let kvComponents = Text.split(t, #char('='));
                    let name = switch (kvComponents.next()) {
                        case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                        case (?n) n;
                    };

                    let value = switch (kvComponents.next()) {
                        case (null) null; // value is optional
                        case (?v) ?Text.trim(v, #char('\u{22}')); // Remove quotes. '\u{22}' instead of '\"'. There is a parsing bug
                    };
                    attributes.add({
                        name = name;
                        value = value;
                    });
                };
            };
        };

        #ok({
            name = name;
            attributes = Buffer.toArray(attributes);
        });
    };

    private class TagTokenIterator(t : Text) : Iter.Iter<Result<Text>> {
        let charIter = Text.toIter(t);

        public func next() : ?Result<Text> {
            let charBuffer = Buffer.Buffer<Char>(3);
            var inQuotes = false;

            loop {
                switch (charIter.next()) {
                    case (null) return getTextFromBuffer(charBuffer);
                    case (?c) {
                        // '\u{22}' instead of '\"'. There is a parsing bug
                        if (c == '\u{22}') {
                            inQuotes := not inQuotes;
                        } else if (c == '<' or c == '>') {
                            // Only allowed as tag start/end
                            return ?#error("Unexpected character '" # Text.fromChar(c) # "'");
                        } else {
                            if (not inQuotes) {
                                if (Utf8.isWhitespace(c)) {
                                    return getTextFromBuffer(charBuffer);
                                };
                            };
                            charBuffer.add(c);
                        };
                    };
                };
            };
        };

        private func getTextFromBuffer(charBuffer : Buffer.Buffer<Char>) : ?{
            #ok : Text;
        } {
            if (charBuffer.size() < 1) {
                return null;
            };
            return ?#ok(Text.fromIter(charBuffer.vals()));
        };
    };

    private func parseTagToken(reader : Utf8.Reader) : Result<Types.Token> {
        let tagValue : Text = switch (reader.readUntil(#char('>'), true)) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (?v) {
                let tagValue : Text = Text.trim(Text.trim(v, #char('>')), #char('<'));

                if (Nat.sub(v.size(), tagValue.size()) > 2) {
                    // Invalid, more that just one < at the beginning
                    return #error("Unexpected character '<'");
                };
                tagValue;
            };
        };

        let token = if (Text.startsWith(tagValue, #char('/'))) {
            #endTag({
                name = Text.trim(Text.trimStart(tagValue, #char('/')), #char(' ')); // TODO trim all whitespace
            });
        } else if (Text.startsWith(tagValue, #text("!--"))) {
            #comment(Text.trim(Text.trim(tagValue, #text("!")), #text("--")));
        } else if (Text.startsWith(tagValue, #char('?'))) {
            let tagInfo : Types.TagInfo = switch (getTagInfo(Text.trim(tagValue, #char('?')))) {
                case (#error(e)) return #error(e);
                case (#ok(t)) t;
            };
            switch (toLower(tagInfo.name)) {
                case "xml" {
                    var encoding : ?Text = null;
                    var major : Nat = 1;
                    var minor : Nat = 0;
                    var standalone : ?Bool = null;
                    for (attr in Iter.fromArray(tagInfo.attributes)) {
                        switch (toLower(attr.name)) {
                            case "encoding" {
                                encoding := attr.value;
                            };
                            case "version" {
                                let versionString = switch (attr.value) {
                                    case (null) return #error("Version attribute specified with no value specified");
                                    case (?v) v;
                                };
                                let versionComponents = Text.split(versionString, #char('.'));
                                major := switch (versionComponents.next()) {
                                    case (null) return #error("Version attribute specified with no value specified");
                                    case (?major) switch (fromText(major)) {
                                        case (null) return #error("Invalid version number '" # versionString # "'");
                                        case (?m) m;
                                    };
                                };
                                minor := switch (versionComponents.next()) {
                                    case (null) 0; // Skip, use default
                                    case (?minor) switch (fromText(minor)) {
                                        case (null) return #error("Invalid version number '" # versionString # "'");
                                        case (?m) m;
                                    };
                                };

                            };
                            case _ {}; // Skip unknown attributes
                        };
                    };
                    #xmlDeclaration({
                        encoding = encoding;
                        version = { major; minor };
                        standalone = standalone;
                    });
                };
                case _ #processingInstruction({
                    attributes = tagInfo.attributes;
                    target = tagInfo.name;
                });
            };

        } else {
            let trimmedTagValue = Text.trimEnd(tagValue, #char('/'));

            let isSelfClosing = trimmedTagValue.size() != tagValue.size(); // Check to see if the / was removed, if it was, then self closing

            let tagInfo : Types.TagInfo = switch (getTagInfo(trimmedTagValue)) {
                case (#error(e)) return #error(e);
                case (#ok(t)) t;
            };

            #startTag({
                tagInfo with selfClosing = isSelfClosing
            });
        };
        #ok(token);
    };

    private func toLower(text : Text) : Text {
        text; // TODO
    };

    private func fromText(value : Text) : ?Nat {
        // TODO
        switch (value) {
            case "0" ?0;
            case "1" ?1;
            case _ Debug.trap("Unrecognized number");
        };
    };
};
