import Utf8 "Utf8";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Char "mo:base/Char";

module {

    public type Attribute = {
        key : Text;
        value : Text;
    };

    public type TagInfo = {
        name : Text;
        attributes : [Attribute];
    };

    public type Token = {
        #startTag : TagInfo and { selfClosing : Bool };
        #endTag : { name : Text };
        #text : Text;
        #comment : Text;
        #processingInstructions : TagInfo;
    };

    public type TokenResult = { #ok : Token; #invalidToken };

    public func tokenizeText(value : Text) : ?[Token] {
        let reader = Utf8.Reader(Text.toIter(value));
        return tokenize(reader);
    };

    public func tokenizeBlob(value : Blob) : ?[Token] {
        let reader = Utf8.Reader(Utf8.Utf8Iter(value.vals()));
        return tokenize(reader);
    };

    public func tokenizeBytes(value : [Nat8]) : ?[Token] {
        let reader = Utf8.Reader(Utf8.Utf8Iter(value.vals()));
        return tokenize(reader);
    };

    public func tokenize(reader : Utf8.Reader) : ?[Token] {
        let tokenBuffer = Buffer.Buffer<Token>(2);
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
        #ok : Token;
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
                        charBuffer.add(c);
                        let _ = reader.next();
                    };
                };
            };
        };
    };

    private func getTagInfo(t : Text) : ?TagInfo {
        do ? {
            let tagTokens : Iter.Iter<Text> = TagTokenIterator(t);

            let name : Text = tagTokens.next()!;

            let attributes = Buffer.Buffer<Attribute>(0);

            label l loop {
                let attribute = switch (tagTokens.next()) {
                    case (null) {
                        break l;
                    };
                    case (?t) {
                        let kvComponents = Text.split(t, #char('='));
                        let key = kvComponents.next()!;
                        let value = kvComponents.next()!;
                        attributes.add({
                            key = key;
                            value = Text.trim(value, #char(Text.toIter("\"").next()!)); // TODO how to do a single double quote character
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

    private class TagTokenIterator(t : Text) : Iter.Iter<Text> {
        let charIter = Text.toIter(t);

        public func next() : ?Text {
            let charBuffer = Buffer.Buffer<Char>(3);
            var inQuotes = false;
            loop {
                switch (charIter.next()) {
                    case (null) return getTextFromBuffer(charBuffer);
                    case (?c) {
                        // TODO how to do a single double quote character
                        if (?c == Text.toIter("\"").next()) {
                            inQuotes := not inQuotes;
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

        private func getTextFromBuffer(charBuffer : Buffer.Buffer<Char>) : ?Text {
            if (charBuffer.size() < 1) {
                return null;
            };
            return ?Text.fromIter(charBuffer.vals());
        };
    };

    private func parseTagToken(reader : Utf8.Reader) : ?Token {
        do ? {
            let tagValue : Text = Text.trim(Text.trim(reader.readUntil(#char('>'), true)!, #char('>')), #char('<'));

            if (Text.startsWith(tagValue, #char('/'))) {
                #endTag({ name = Text.trimStart(tagValue, #char('/')) });
            } else if (Text.startsWith(tagValue, #text("!--"))) {
                let commentValue : Text = reader.readUntil(#text("--!>"), true)!;
                #comment(commentValue);
            } else if (Text.startsWith(tagValue, #char('?'))) {
                if (not Text.endsWith(tagValue, #char('?'))) {
                    // Must end in '?'
                    return null;
                };
                let tagInfo : TagInfo = getTagInfo(Text.trim(tagValue, #char('?')))!;
                #processingInstructions(tagInfo);

            } else {
                let trimmedTagValue = Text.trimEnd(tagValue, #char('/'));

                let isSelfClosing = trimmedTagValue.size() != tagValue.size(); // Check to see if the / was removed, if it was, then self closing

                let tagInfo : TagInfo = getTagInfo(trimmedTagValue)!;

                #startTag({
                    tagInfo with selfClosing = isSelfClosing
                });
            };
        };
    };
};
