import Utf8 "Utf8";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Char "mo:base/Char";
import Types "Types";
import Nat "mo:base/Nat";
import NatX "mo:xtended-numbers/NatX";

// TODO escape & < > ' "
// TODO <![CDATA[ ]]> escapes whats inside

module {

    public type TokenResult = { #ok : Types.Token; #invalidToken };

    public func tokenizeText(value : Text) : ?[Types.Token] {
        let reader = Utf8.Reader(Text.toIter(value));
        return tokenize(reader);
    };

    public func tokenizeBlob(value : Blob) : ?[Types.Token] {
        let reader = Utf8.Reader(Utf8.Utf8Iter(value.vals()));
        return tokenize(reader);
    };

    public func tokenizeBytes(value : [Nat8]) : ?[Types.Token] {
        let reader = Utf8.Reader(Utf8.Utf8Iter(value.vals()));
        return tokenize(reader);
    };

    public func tokenize(reader : Utf8.Reader) : ?[Types.Token] {
        let tokenBuffer = Buffer.Buffer<Types.Token>(2);
        loop {
            switch (getNext(reader)) {
                case (#ok(t)) {
                    tokenBuffer.add(t);
                };
                case (#end) return ?Buffer.toArray(tokenBuffer);
                case (#invalidToken) return null;
            };
        };
    };

    private func getNext(reader : Utf8.Reader) : {
        #ok : Types.Token;
        #end;
        #invalidToken;
    } {
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
                            let textValue = Text.fromIter(charBuffer.vals());
                            #text(textValue);
                        } else {
                            switch (parseTagToken(reader)) {
                                case (null) return #invalidToken;
                                case (?t) t;
                            };
                        };
                        return #ok(token);
                    } else {
                        switch (c) {
                            // < and > are only allowed in the context of tags
                            // must be escaped for text
                            case ('>') return #invalidToken;
                            case (_)(); // Skip
                        };
                        charBuffer.add(c);
                        let _ = reader.next();
                    };
                };
            };
        };
    };

    private func getTagInfo(t : Text) : ?Types.TagInfo {
        do ? {
            let tagTokens : Iter.Iter<TagToken> = TagTokenIterator(t);

            let name : Text = switch (tagTokens.next()!) {
                case (#invalid) return null;
                case (#tag(t)) t;
            };

            let attributes = Buffer.Buffer<Types.Attribute>(0);

            label l loop {
                let attribute = switch (tagTokens.next()) {
                    case (null) {
                        break l;
                    };
                    case (?#invalid) {
                        return null;
                    };
                    case (?#tag(t)) {
                        let kvComponents = Text.split(t, #char('='));
                        let name = kvComponents.next()!;

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

            {
                name = name;
                attributes = Buffer.toArray(attributes);
            };
        };
    };

    private type TagToken = {
        #tag : Text;
        #invalid;
    };
    private class TagTokenIterator(t : Text) : Iter.Iter<TagToken> {
        let charIter = Text.toIter(t);

        public func next() : ?TagToken {
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
                            return ?#invalid;
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
            #tag : Text;
        } {
            if (charBuffer.size() < 1) {
                return null;
            };
            return ?#tag(Text.fromIter(charBuffer.vals()));
        };
    };

    private func parseTagToken(reader : Utf8.Reader) : ?Types.Token {
        do ? {
            let untrimmedTagValue : Text = reader.readUntil(#char('>'), true)!;

            let tagValue : Text = Text.trim(Text.trim(untrimmedTagValue, #char('>')), #char('<'));

            if (Nat.sub(untrimmedTagValue.size(), tagValue.size()) > 2) {
                // Invalid, more that just one < at the beginnin
                return null;
            };

            if (Text.startsWith(tagValue, #char('/'))) {
                #endTag({
                    name = Text.trim(Text.trimStart(tagValue, #char('/')), #char(' ')); // TODO trim all whitespace
                });
            } else if (Text.startsWith(tagValue, #text("!--"))) {
                #comment(Text.trim(Text.trim(tagValue, #text("!")), #text("--")));
            } else if (Text.startsWith(tagValue, #char('?'))) {
                if (not Text.endsWith(tagValue, #char('?'))) {
                    // Must end in '?'
                    return null;
                };
                let tagInfo : Types.TagInfo = getTagInfo(Text.trim(tagValue, #char('?')))!;
                switch (tagInfo.name) {
                    // TODO toLower??
                    case "xml" {
                        var encoding : ?Text = null;
                        var major : Nat = 1;
                        var minor : Nat = 0;
                        var standalone : ?Bool = null;
                        for (attr in Iter.fromArray(tagInfo.attributes)) {
                            // TODO toLower
                            switch (attr.name) {
                                case "encoding" {
                                    encoding := attr.value;
                                };
                                case "version" {
                                    let versionComponents = Text.split(attr.value!, #char('.'));
                                    major := fromText(versionComponents.next()!)!;
                                    switch (versionComponents.next()) {
                                        case (null) {}; // Skip, use default
                                        case (?m) {
                                            minor := fromText(m)!;
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

                let tagInfo : Types.TagInfo = getTagInfo(trimmedTagValue)!;

                #startTag({
                    tagInfo with selfClosing = isSelfClosing
                });
            };
        };
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
