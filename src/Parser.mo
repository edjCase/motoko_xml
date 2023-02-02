import Lexer "Lexer";
import Types "Types";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";

module {

    public func parseDocument(tokens : Iter.Iter<Types.Token>) : ?Types.Document {
        do ? {
            var version : ?Types.Version = null;
            var encoding : ?Text = null;
            var standalone : ?Bool = null;
            let processingInstructions = Buffer.Buffer<Types.ProcessingInstruction>(1);
            loop {
                switch (tokens.next()!) {
                    case (#xmlDeclaration(x)) {
                        version := ?x.version;
                        encoding := x.encoding;
                    };
                    case (#comment(c)) {
                        // Skip
                    };
                    case (#processingInstruction(p)) {
                        processingInstructions.add(p);
                    };
                    case (#startTag(tag)) {
                        let root = parseElement(tokens, tag, tag.selfClosing)!;
                        // TODO check things after root?
                        return ?{
                            version = version;
                            encoding = encoding;
                            root = root;
                            standalone = standalone;
                            processInstructions = Buffer.toArray(processingInstructions);
                        };
                    };
                    case (_) return null;
                };
            };
        };
    };

    private func parseElement(tokens : Iter.Iter<Types.Token>, startTag : Types.TagInfo, selfClosing : Bool) : ?Types.Element {
        do ? {
            if (selfClosing) {
                return ?{
                    name = startTag.name;
                    attributes = startTag.attributes;
                    children = #selfClosing;
                };
            };
            let children = Buffer.Buffer<Types.ElementChild>(1);
            label l loop {
                switch (tokens.next()!) {
                    case (#startTag(tag)) {
                        let inner = parseElement(tokens, tag, tag.selfClosing)!;
                        children.add(#element(inner));
                    };
                    case (#text(t)) {
                        children.add(#text(t));
                    };
                    case (#comment(c)) {
                        children.add(#comment(c));
                    };
                    case _ return null; // Invalid type
                };
            };
            return ?{
                name = startTag.name;
                attributes = startTag.attributes;
                children = #open(Buffer.toArray(children));
            };
        };
    };
};
