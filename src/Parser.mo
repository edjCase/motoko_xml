import Tokenizer "Tokenizer";
import Types "Types";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Debug "mo:base/Debug";

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
                        // Check for tokens after the root
                        // Only allow for comments
                        switch (getNonCommentTokens(tokens)) {
                            case (null) {
                                // Valid
                            };
                            case (?tokens) {
                                if (tokens.size() > 0) {
                                    return null; // Invalid
                                };
                            };
                        };

                        return ?{
                            version = version;
                            encoding = encoding;
                            root = root;
                            standalone = standalone;
                            processInstructions = Buffer.toArray(processingInstructions);
                        };
                    };
                    case (t) return null; // Invalid type
                };
            };
        };
    };

    private func getNonCommentTokens(tokens : Iter.Iter<Types.Token>) : ?[Types.Token] {
        var buffer : ?Buffer.Buffer<Types.Token> = null;
        loop {
            switch (tokens.next()) {
                case (?#comment(c)) {
                    // Skip
                };
                case (null) {
                    // Reached end
                    switch (buffer) {
                        case (null) return null;
                        case (?b) return ?Buffer.toArray(b);
                    };
                };
                case (?t) {
                    let b = switch (buffer) {
                        // Create buffer if none exists
                        case (null) {
                            let b = Buffer.Buffer<Types.Token>(1);
                            buffer := ?b;
                            b;
                        };
                        case (?b) b;
                    };
                    // Add invalid token
                    b.add(t);
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
                    case (#endTag(t)) {
                        if (t.name != startTag.name) {
                            Debug.trap(t.name # " " # startTag.name);
                            return null;
                        };
                        break l;
                    };
                    case (#text(t)) {
                        children.add(#text(t));
                    };
                    case (#comment(c)) {
                        children.add(#comment(c));
                    };
                    case t return null; // Invalid type
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
