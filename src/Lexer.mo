import Utf8 "Utf8";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Iter "mo:base/Iter";

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
                    };
                };
            };
        };
    };

    private func getTagInfo(t : Text) : ?TagInfo {
        do ? {
            let tagTokens : Iter.Iter<Text> = Text.split(t, #predicate(Utf8.isWhitespace));

            let name : Text = tagTokens.next()!;

            let attributes = Buffer.Buffer<Attribute>(0);

            label l loop {
                // TODO can there be spaces between the key, value and '='
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

    private func parseTagToken(reader : Utf8.Reader) : ?Token {
        do ? {
            let tagValue : Text = Text.trim(reader.readUntil(#char('>'), true)!, #char('>'));

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
                let tagInfo : TagInfo = getTagInfo(tagValue)!;
                let last = reader.next();
                let isSelfClosing = last == ?'/';
                #startTag({
                    tagInfo with selfClosing = isSelfClosing
                });
            };
        };
    };
};
