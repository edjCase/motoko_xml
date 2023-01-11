import Utf8 "Utf8";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";

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
        #endTag;
        #text : Text;
        #comment : Text;
        #processingInstructions : TagInfo;
    };

    private class Lexer(reader : Utf8.Reader) {

        public func get() : ?[Token] {
            let tokenBuffer = Buffer.Buffer<Token>(1);
            do ? {
                loop {
                    switch (getNext(reader)!) {
                        case (#token(t)) tokenBuffer.add(t);
                        case (#end) return ?Buffer.toArray(tokenBuffer);
                    };
                };
            };
        };

        private func getNext(reader : Utf8.Reader) : ?{ #token : Token; #end } {
            reader.skipWhitespace();
            do ? {
                let token : Token = switch (reader.next()) {
                    case (?'<') {
                        let tagReader = readUntil(reader, '>')!;

                        let isProcessingInstructions = tagReader.peek() == ?'?';

                        if (isProcessingInstructions) {
                            let _ = tagReader.next(); // Discard '?'
                        };
                        let name : Text = reader.readUntilWhitespace()!;
                        let attributes = Buffer.Buffer<Attribute>(0);
                        // TODO
                        // loop {

                        // };

                        let tagInfo = {
                            name = name;
                            attributes = Buffer.toArray(attributes);
                        };
                        if (isProcessingInstructions) {
                            let last = reader.next()!;
                            if (last != '?') {
                                // Must end in '?>'
                                return null;
                            };
                            #processingInstructions(tagInfo);
                        } else {
                            let last = reader.next();
                            let isSelfClosing = last == ?'/';
                            #startTag({
                                tagInfo with selfClosing = isSelfClosing
                            });
                        };
                    };
                    case (?'/') {
                        #comment();
                    };
                    case (?c) {
                        let value = readUntil(reader, '<')!; // TODO what about comment?
                        #text(value);
                    };
                    case (null) return ?#end;
                };
                #token(token);
            };
        };

        private func readUntil(reader : Utf8.Reader, c : Char) : ?Utf8.Reader {

        };

        //     private func getTag(tokenBuffer : Buffer.Buffer<Token>) : ?Tag {
        //         do ? {
        //             let open = reader.next()!;
        //             if (open != '<') {
        //                 return null;
        //             };
        //             let isClosingTag = reader.peek()! == '/';
        //             if (isClosingTag) {
        //                 let _ = reader.next();
        //             };
        //             let name : Text = reader.nextWord()!;
        //             let inText = false;
        //             var previousChar : ?Char = null;

        //             let attributesBuffer = Buffer.Buffer<Attribute>(0);
        //             label main loop {
        //                 reader.skipWhitespace();
        //                 let c : Char = reader.peek()!;
        //                 if (c == '>') {
        //                     let _ = reader.next()!; // read the peek
        //                     let style = switch (previousChar) {
        //                         case (?'/') #selfClosing;
        //                         case (p) {
        //                             if (isClosingTag) { #closing } else { #opening };
        //                         };
        //                     };
        //                     return ?{
        //                         name = name;
        //                         attributes = Buffer.toArray(attributesBuffer);
        //                         style = style;
        //                     };
        //                 } else if (c == '/' or c == '?') {
        //                     let _ = reader.next();
        //                     //Skip
        //                 } else {
        //                     let attributeText = reader.nextWord()!;
        //                     let splitValues : Iter.Iter<Text> = Text.split(attributeText, #char('='));
        //                     let attributeName = splitValues.next()!;
        //                     let quoteChar = Text.toIter("\"").next()!; // TODO how to do '\"'??
        //                     let attributeValue : ?Text = switch (splitValues.next()) {
        //                         case (null) null;
        //                         case (?v) ?Text.trim(v, #char(quoteChar)); // Trim quotes
        //                     };
        //                     if (splitValues.next() != null) {
        //                         return null; // Should only be 1 or 2 values
        //                     };
        //                     attributesBuffer.add({
        //                         name = attributeName;
        //                         value = attributeValue;
        //                     });
        //                 };
        //                 previousChar := reader.current();
        //             };
        //             return null;
        //         };
        //     };
        // };
    };
};
