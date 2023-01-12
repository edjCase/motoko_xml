import Lexer "Lexer";
import Types "Types";
import Iter "mo:base/Iter";

module {

    public func parse(tokens : [Lexer.Token]) : {
        #ok : Types.Document;
        #err;
    } {
        let xmlReader = XMLReader(reader);
        let tokens : [Lexer.Token] = switch (xmlReader.get()) {
            case (#ok(t)) t;
            case (#err(t)) return #err(t);
        };
        let a = do ? {
            if (tokens.size() < 2) {
                return #err(tokens);
            };
            let tokenIter = Iter.fromArray(tokens);
            let headerTag = switch (tokenIter.next()!) {
                case (#text(txt)) {
                    return null; // Invalid
                };
                case (#tag(tag)) tag;
            };
            let version : Text = switch (Array.find<Attribute>(headerTag.attributes, func(a) { a.name == "version" })) {
                case (null) return #err(tokens); // TODO default version?
                case (?v) v.value!;
            };
            let encoding : Text = switch (Array.find<Attribute>(headerTag.attributes, func(a) { a.name == "encoding" })) {
                case (null) return #err(tokens); // TODO default encoding?
                case (?v) v.value!;
            };
            let root = switch (buildXml(tokenIter)) {
                case (null) return #err(tokens);
                case (?#node(n)) n;
                case (?#text(t)) return #err(tokens);
            };
            {
                version = version;
                encoding = encoding;
                root = root;
            };
        };
        switch (a) {
            case (null) #err(tokens);
            case (?a) #ok(a);
        };
    };

    private func buildXml(i : Iter.Iter<Lexer.Token>) : ?{
        #element : Types.Element;
        #text : Text;
    } {
        do ? {
            switch (i.next()!) {
                case (?#tag(tag)) {
                    #element(buildNode(i, tag)!);
                };
                case (?#text(txt)) {
                    #text(txt);
                };
            };
        };
    };

    private func buildNode(i : Iter.Iter<Lexer.Token>, startTag : Tag) : ?Node {
        do ? {
            switch (startTag.style) {
                case (#closing) return null;
                case (#selfClosing) return ?{
                    name = startTag.name;
                    attributes = startTag.attributes;
                    children = #selfClosing;
                };
                case (#opening) {
                    let children = Buffer.Buffer<NodeOrText>(1);
                    label l loop {
                        let next = i.next()!;
                        switch (next) {
                            case (#tag(tag)) {
                                let n = switch (tag.style) {
                                    case (#opening or #selfClosing) {
                                        buildNode(i, tag)!;
                                    };
                                    case (#closing) {
                                        if (tag.name == startTag.name) {
                                            // Tag is closed
                                            break l;
                                        };
                                        return null; // Invalid
                                    };
                                };
                                children.add(#node(n));
                            };
                            case (#text(t)) {
                                children.add(#text(t));
                            };
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
    };
};
