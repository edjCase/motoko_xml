import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Token "Token";
import Document "Document";

module {

    public type ParseError = {
        #unexpectedEndOfTokens;
        #tokensAfterRoot;
        #unexpectedToken : Token.Token;
    };

    public type ParseResult<T> = Result.Result<T, ParseError>;

    public func parseDocument(tokens : Iter.Iter<Token.Token>) : ParseResult<Document.Document> {
        var version : ?Document.Version = null;
        var encoding : ?Text = null;
        var standalone : ?Bool = null;
        var docType : ?Document.DocType = null;
        let processingInstructions = Buffer.Buffer<Document.ProcessingInstruction>(1);
        loop {
            switch (tokens.next()) {
                case (null) return #err(#unexpectedEndOfTokens);
                case (?#xmlDeclaration(x)) {
                    version := ?x.version;
                    encoding := x.encoding;
                };
                case (?#comment(_)) {
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
                        case (#err(e)) return #err(e);
                    };
                    // Check for tokens after the root
                    // Only allow for comments
                    switch (getNonCommentTokens(tokens)) {
                        case (null) {
                            // Valid
                        };
                        case (?tokens) {
                            if (tokens.size() > 0) {
                                return #err(#tokensAfterRoot);
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
                case (?t) return #err(#unexpectedToken(t));
            };
        };
    };

    private func getNonCommentTokens(tokens : Iter.Iter<Token.Token>) : ?[Token.Token] {
        var buffer : ?Buffer.Buffer<Token.Token> = null;
        loop {
            switch (tokens.next()) {
                case (?#comment(_)) {
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
                            let b = Buffer.Buffer<Token.Token>(1);
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
        tokens : Iter.Iter<Token.Token>,
        startTag : Token.StartTagInfo,
        selfClosing : Bool,
    ) : ParseResult<Document.Element> {
        if (selfClosing) {
            return #ok({
                name = startTag.name;
                attributes = startTag.attributes;
                children = #selfClosing;
            });
        };
        let children = Buffer.Buffer<Document.ElementChild>(1);
        label l loop {
            switch (tokens.next()) {
                case (null) {};
                case (?#startTag(tag)) {
                    switch (parseElement(tokens, tag, tag.selfClosing)) {
                        case (#ok(inner)) {
                            children.add(#element(inner));
                        };
                        case (#err(e)) return #err(e);
                    };
                };
                case (?#endTag(t)) {
                    if (t.name != startTag.name) {
                        return #err(#unexpectedToken(#startTag(startTag)));
                    };
                    break l;
                };
                case (?#text(t)) {
                    children.add(#text(t));
                };
                case (?#comment(c)) {
                    children.add(#comment(c));
                };
                case (?#cdata(c)) {
                    children.add(#cdata(c));
                };
                case (?t) return #err(#unexpectedToken(t));
            };
        };

        return #ok({
            name = startTag.name;
            attributes = startTag.attributes;
            children = #open(Buffer.toArray(children));
        });
    };
};
