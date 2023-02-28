import Tokenizer "Tokenizer";
import Types "Types";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Debug "mo:base/Debug";

module {

    public type ParseError = {
        #unexpectedEndOfTokens;
        #tokensAfterRoot;
        #unexpectedToken : Types.Token;
    };

    public type ParseResult<T> = {
        #ok : T;
        #error : ParseError;
    };

    public func parseDocument(tokens : Iter.Iter<Types.Token>) : ParseResult<Types.Document> {
        var version : ?Types.Version = null;
        var encoding : ?Text = null;
        var standalone : ?Bool = null;
        var docType : ?Types.DocType = null;
        let processingInstructions = Buffer.Buffer<Types.ProcessingInstruction>(1);
        loop {
            switch (tokens.next()) {
                case (null) return #error(#unexpectedEndOfTokens);
                case (?#xmlDeclaration(x)) {
                    version := ?x.version;
                    encoding := x.encoding;
                };
                case (?#comment(c)) {
                    // Skip
                };
                case (?#processingInstruction(p)) {
                    processingInstructions.add(p);
                };
                case (?#docType(d)) {
                    docType := ?d;
                };
                case (?#startTag(tag)) {
                    let root = switch (parseElement(tokens, tag, tag.selfClosing)) {
                        case (#ok(e)) e;
                        case (#error(e)) return #error(e);
                    };
                    // Check for tokens after the root
                    // Only allow for comments
                    switch (getNonCommentTokens(tokens)) {
                        case (null) {
                            // Valid
                        };
                        case (?tokens) {
                            if (tokens.size() > 0) {
                                return #error(#tokensAfterRoot);
                            };
                        };
                    };

                    return #ok({
                        version = version;
                        encoding = encoding;
                        root = root;
                        standalone = standalone;
                        processInstructions = Buffer.toArray(processingInstructions);
                        docType = docType;
                    });
                };
                case (?t) return #error(#unexpectedToken(t));
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

    private func parseElement(
        tokens : Iter.Iter<Types.Token>,
        startTag : Types.StartTagInfo,
        selfClosing : Bool,
    ) : ParseResult<Types.Element> {
        if (selfClosing) {
            return #ok({
                name = startTag.name;
                attributes = startTag.attributes;
                children = #selfClosing;
            });
        };
        let children = Buffer.Buffer<Types.ElementChild>(1);
        label l loop {
            switch (tokens.next()) {
                case (null) {};
                case (?#startTag(tag)) {
                    switch (parseElement(tokens, tag, tag.selfClosing)) {
                        case (#ok(inner)) {
                            children.add(#element(inner));
                        };
                        case (#error(e)) return #error(e);
                    };
                };
                case (?#endTag(t)) {
                    if (t.name != startTag.name) {
                        return #error(#unexpectedToken(#startTag(startTag)));
                    };
                    break l;
                };
                case (?#text(t)) {
                    children.add(#text(t));
                };
                case (?#comment(c)) {
                    children.add(#comment(c));
                };
                case (?t) return #error(#unexpectedToken(t));
            };
        };

        return #ok({
            name = startTag.name;
            attributes = startTag.attributes;
            children = #open(Buffer.toArray(children));
        });
    };
};
