import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Char "mo:base/Char";
import Nat "mo:base/Nat";
import NatX "mo:xtended-numbers/NatX";
import TextX "mo:xtended-text/TextX";
import IterX "IterX";
import TextSlice "TextSlice";
import Token "Token";
import Document "Document";

module {

    public let UNEXPECTED_ERROR_MESSAGE = "Unexpected end of characters";

    type Result<T> = { #ok : T; #error : Text };

    public type TokenizeResult = Result<[Token.Token]>;

    public func tokenize(value : Iter.Iter<Char>) : TokenizeResult {
        let reader = IterX.IterReader<Char>(value);
        let tokenBuffer = Buffer.Buffer<Token.Token>(2);
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

    private func getNext(reader : IterX.IterReader<Char>) : Result<Token.Token> or {
        #end;
    } {
        skipWhitespace(reader);
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
                            #text(Text.fromIter(charBuffer.vals()));
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
                            case (_) (); // Skip
                        };
                        charBuffer.add(c);
                        let _ = reader.next();
                    };
                };
            };
        };
    };

    private func getTagInfo(tag : TextSlice.TextSlice) : Result<Token.TagInfo> {
        let tagTokens : Iter.Iter<Result<TextSlice.TextSlice>> = TagTokenIterator(tag);

        let name : TextSlice.TextSlice = switch (tagTokens.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (?t) switch (t) {
                case (#error(e)) return #error(e);
                case (#ok(t)) t;
            };
        };

        let attributes = Buffer.Buffer<Document.Attribute>(0);

        label l loop {
            switch (tagTokens.next()) {
                case (null) {
                    break l;
                };
                case (? #error(e)) {
                    return #error(e);
                };
                case (? #ok(t)) {
                    switch (splitAttribute(t)) {
                        case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                        case (?(name : Text, value : ?Text)) {

                            attributes.add({
                                name = name;
                                value = value;
                            });
                        };
                    };
                };
            };
        };

        #ok({
            name = name.trimWhitespace().toText();
            attributes = Buffer.toArray(attributes);
        });
    };

    private func splitAttribute(slice : TextSlice.TextSlice) : ?(Text, ?Text) {
        switch (slice.indexOfSequence(#text("="))) {
            case (null) {
                // No equals sign, so just the name with no value
                ?(slice.toText(), null);
            };
            case (?index) {
                // split
                let name = slice.slice(0, ?index);
                let value = slice.slice(index + 1, null).trimSingle('\"');

                ?(name.toText(), ?value.toText());
            };
        };
    };

    private func parseTagToken(reader : IterX.IterReader<Char>) : Result<Token.Token> {
        matchAndParseSlice(
            reader,
            [
                {
                    startsWith = TextSlice.fromText("</");
                    endsWith = #text(TextSlice.fromText(">"));
                    parse = parseEndTag;
                },
                {
                    startsWith = TextSlice.fromText("<!--");
                    endsWith = #text(TextSlice.fromText("-->"));
                    parse = parseComment;
                },
                {
                    startsWith = TextSlice.fromText("<?");
                    endsWith = #text(TextSlice.fromText("?>"));
                    parse = parseQ;
                },
                {
                    startsWith = TextSlice.fromText("<![CDATA[");
                    endsWith = #text(TextSlice.fromText("]]>"));
                    parse = parseCDATA;
                },
                {
                    startsWith = TextSlice.fromText("<!DOCTYPE");
                    endsWith = #custom(
                        func(iter : Iter.Iter<Char>) : ?(TextSlice.TextSlice, Nat) {
                            do ? {
                                var depth = 0;
                                let buffer = Buffer.Buffer<Char>(20);
                                label l loop {
                                    let c = iter.next()!;
                                    // Loop until we find the end of the doctype
                                    // but there are nested tags
                                    if (c == '>') {
                                        if (depth == 1) {
                                            break l;
                                        } else {
                                            depth := depth - 1;
                                        };
                                    } else if (c == '<') {
                                        depth := depth + 1;
                                    };
                                    buffer.add(c);
                                };

                                (TextSlice.slice(#buffer(buffer), 0, null), 1);
                            };
                        }
                    );
                    parse = parseDocType;
                },
                {
                    startsWith = TextSlice.fromText("<");
                    endsWith = #text(TextSlice.fromText(">"));
                    parse = parseStartTag;
                },
            ],
        );
    };

    private func parseDocType(slice : TextSlice.TextSlice) : Result<Token.Token> {
        let iter = TagTokenIterator(slice);
        let rootElementName : Text = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (? #error(e)) return #error(e);
            case (? #ok(t)) t.toText();
        };
        let (externalTypes : ?Document.ExternalTypesDefinition, internalTypes : [Document.InternalDocumentTypeDefinition]) = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (? #error(e)) return #error(e);
            case (? #ok(t)) {
                switch (TextX.toUpper(t.toText())) {
                    case ("PUBLIC") {
                        let publicId = switch (iter.next()) {
                            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                            case (? #error(e)) return #error(e);
                            case (? #ok(t)) t.toText();
                        };
                        let url = switch (iter.next()) {
                            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                            case (? #error(e)) return #error(e);
                            case (? #ok(t)) t.toText();
                        };
                        let externalTypes : ?Document.ExternalTypesDefinition = ? #public_({
                            id = publicId;
                            url = url;
                        });
                        let internalTypes : [Document.InternalDocumentTypeDefinition] = switch (parseInternalTypes(iter.toReader())) {
                            case (#error(e)) return #error(e);
                            case (#ok(t)) t;
                        };
                        (externalTypes, internalTypes);
                    };
                    case ("SYSTEM") {
                        let url = switch (iter.next()) {
                            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                            case (? #error(e)) return #error(e);
                            case (? #ok(t)) t;
                        };
                        let externalTypes : ?Document.ExternalTypesDefinition = ? #system_({
                            url = url.toText();
                        });
                        let internalTypes : [Document.InternalDocumentTypeDefinition] = switch (parseInternalTypes(iter.toReader())) {
                            case (#error(e)) return #error(e);
                            case (#ok(t)) t;
                        };
                        (externalTypes, internalTypes);
                    };
                    case ("[") {
                        let externalTypes : ?Document.ExternalTypesDefinition = null;
                        let internalTypes : [Document.InternalDocumentTypeDefinition] = switch (parseInternalTypes(iter.toReader())) {
                            case (#error(e)) return #error(e);
                            case (#ok(t)) t;
                        };
                        (externalTypes, internalTypes);
                    };
                    case (_) return #error(UNEXPECTED_ERROR_MESSAGE);
                };
            };
        };
        #ok(
            #docType({
                rootElementName = rootElementName;
                typeDefinition = {
                    externalTypes = externalTypes;
                    internalTypes = internalTypes;
                };
            })
        );
    };

    private func parseInternalTypes(reader : IterX.IterReader<Char>) : Result<[Document.InternalDocumentTypeDefinition]> {
        let internalTypes = Buffer.Buffer<Document.InternalDocumentTypeDefinition>(2);
        label l loop {
            skipWhitespace(reader);
            if (reader.peek() == ?']' or reader.peek() == null) {
                break l;
            };
            let r = matchAndParseSlice<Document.InternalDocumentTypeDefinition>(
                reader,
                [
                    {
                        startsWith = TextSlice.fromText("<!ENTITY");
                        endsWith = #text(TextSlice.fromText(">"));
                        parse = parseEntity;
                    },
                    {
                        startsWith = TextSlice.fromText("<!ELEMENT");
                        endsWith = #text(TextSlice.fromText(">"));
                        parse = parseElement;
                    },
                    {
                        startsWith = TextSlice.fromText("<!ATTLIST");
                        endsWith = #text(TextSlice.fromText(">"));
                        parse = parseAttribute;
                    },
                    {
                        startsWith = TextSlice.fromText("<!NOTATION");
                        endsWith = #text(TextSlice.fromText(">"));
                        parse = parseNotation;
                    },
                    {
                        startsWith = TextSlice.fromText("<!--");
                        endsWith = #text(TextSlice.fromText("-->"));
                        parse = parseComment;
                    },
                ],
            );
            switch (r) {
                case (#error(e)) return #error(e);
                case (#ok(t)) {
                    internalTypes.add(t);
                };
            };
        };
        #ok(Buffer.toArray(internalTypes));
    };

    private func parseEntity(slice : TextSlice.TextSlice) : Result<Document.InternalDocumentTypeDefinition> {
        let iter = TagTokenIterator(slice);
        let nameOrPercent = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (? #error(e)) return #error(e);
            case (? #ok(t)) t;
        };

        let token : Document.InternalDocumentTypeDefinition = if (nameOrPercent.size() == 1 and nameOrPercent.get(0) == '%') {
            let name = switch (iter.next()) {
                case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                case (? #error(e)) return #error(e);
                case (? #ok(t)) t.toText();
            };
            let kind = switch (iter.next()) {
                case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                case (? #error(e)) return #error(e);
                case (? #ok(t)) t.toText();
            };
            let type_ = switch (kind) {
                case ("SYSTEM") {
                    let url = switch (iter.next()) {
                        case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                        case (? #error(e)) return #error(e);
                        case (? #ok(t)) t.trimSingle('\"').toText();
                    };
                    #external({
                        type_ = #system_;
                        url = url;
                    });
                };
                case ("PUBLIC") {
                    let publicId = switch (iter.next()) {
                        case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                        case (? #error(e)) return #error(e);
                        case (? #ok(t)) t.trimSingle('\"').toText();
                    };
                    let url = switch (iter.next()) {
                        case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                        case (? #error(e)) return #error(e);
                        case (? #ok(t)) t.trimSingle('\"').toText();
                    };
                    #external({
                        type_ = #public_({ id = publicId });
                        url = url;
                    });
                };
                case (entityValue) {
                    #internal(Text.trim(entityValue, #char('\"')));
                };
            };

            #parameterEntity({
                name = name;
                type_ = type_;
            });
        } else {
            let name = nameOrPercent.toText();
            let kind = switch (iter.next()) {
                case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                case (? #error(e)) return #error(e);
                case (? #ok(t)) t.toText();
            };
            let type_ = switch (kind) {
                case ("SYSTEM") {
                    let url = switch (iter.next()) {
                        case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                        case (? #error(e)) return #error(e);
                        case (? #ok(t)) t.trimSingle('\"').toText();
                    };
                    let notationId : ?Text = switch (parseNotationId(iter)) {
                        case (#error(e)) return #error(e);
                        case (#ok(n)) n;
                    };
                    #external({
                        type_ = #system_;
                        url = url;
                        notationId = notationId;
                    });
                };
                case ("PUBLIC") {
                    let publicId = switch (iter.next()) {
                        case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                        case (? #error(e)) return #error(e);
                        case (? #ok(t)) t.trimSingle('\"').toText();
                    };
                    let url = switch (iter.next()) {
                        case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                        case (? #error(e)) return #error(e);
                        case (? #ok(t)) t.trimSingle('\"').toText();
                    };
                    let notationId : ?Text = switch (parseNotationId(iter)) {
                        case (#error(e)) return #error(e);
                        case (#ok(n)) n;
                    };
                    #external({
                        type_ = #public_({ id = publicId });
                        url = url;
                        notationId = notationId;
                    });
                };
                case (entityValue) {
                    #internal(Text.trim(entityValue, #char('\"')));
                };
            };
            #generalEntity({
                name = name;
                type_ = type_;
            });
        };

        switch (iter.next()) {
            case (null) return #ok(token);
            case (? #error(e)) return #error(e);
            case (? #ok(t)) return #error("Unexpected token '" # t.toText() # "'");
        };
    };

    private func parseNotationId(iter : TagTokenIterator) : Result<?Text> {
        switch (iter.next()) {
            case (null) #ok(null);
            case (? #error(e)) #error(e);
            case (? #ok(t)) {
                let ndata = t.toText();
                if (ndata != "NDATA") {
                    return #error("Unexpected token '" #ndata # "'. Expected 'NDATA'");
                };
                switch (iter.next()) {
                    case (null) #error(UNEXPECTED_ERROR_MESSAGE);
                    case (? #error(e)) #error(e);
                    case (? #ok(t)) #ok(?t.toText());
                };
            };
        };
    };

    private func parseElement(slice : TextSlice.TextSlice) : Result<Document.InternalDocumentTypeDefinition> {
        let iter = TagTokenIterator(slice);
        let name = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (? #error(e)) return #error(e);
            case (? #ok(t)) t.toText();
        };
        let allowableContents : Document.AllowableContents = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (? #error(e)) return #error(e);
            case (? #ok(childSlice)) {
                if (childSlice.get(0) != '(') {
                    switch (childSlice.toText()) {
                        case ("EMPTY") #empty;
                        case ("ANY") #any;
                        case (c) return #error("Unexpected token '" # c # "'. Expected 'EMPTY', 'ANY', or '('");
                    };
                } else {
                    if (childSlice.get(childSlice.size() - 1) != ')') {
                        return #error("Expected ')'");
                    };

                    switch (parseChoiceOrSequence(childSlice)) {
                        case (#error(e)) return #error(e);
                        case (#ok(#choice(children))) {
                            if (children[0].kind == #element("#PCDATA")) {
                                // Mixed when #PCDATA is the first child
                                #mixed(#choice(children));
                            } else {
                                #children(#choice(children));
                            };
                        };
                        case (#ok(#sequence(children))) #children(#sequence(children));
                    };
                };
            };
        };
        #ok(#element({ name = name; allowableContents = allowableContents }));
    };

    private func parseChildElement(childSlice : TextSlice.TextSlice) : Result<Document.ChildElement> {
        // Get the ocurrance suffix and return the slice without it
        let (ocurrance, sliceWithoutOcurrance) = parseOcurrance(childSlice);
        // If not wrapped in parens, it's a single element
        if (sliceWithoutOcurrance.get(0) != '(') {
            return #ok({
                kind = #element(sliceWithoutOcurrance.toText());
                ocurrance = ocurrance;
            });
        };

        // Otherwise, it's a group of elements
        let lastIndex : Nat = sliceWithoutOcurrance.size() - 1;
        if (sliceWithoutOcurrance.get(lastIndex) != ')') {
            // Validate it ends in a ')'
            return #error("Unexpected token '" # Text.fromChar(sliceWithoutOcurrance.get(lastIndex)) # "'. Expected ')'");
        };

        let sliceWithoutParans = sliceWithoutOcurrance.slice(1, ?(lastIndex - 1)); // Remove '(' and ')'
        let kind = switch (parseChoiceOrSequence(sliceWithoutParans)) {
            case (#error(e)) return #error(e);
            case (#ok(k)) k;
        };
        #ok({
            kind = kind;
            ocurrance = ocurrance;
        });
    };

    private func parseOcurrance(slice : TextSlice.TextSlice) : (Document.Ocurrance, TextSlice.TextSlice) {
        let lastIndex : Nat = slice.size() - 1;
        let ocurrance = switch (slice.get(lastIndex)) {
            case ('?') #zeroOrOne;
            case ('*') #zeroOrMore;
            case ('+') #oneOrMore;
            case (_) #one;
        };
        let trimmedSlice = switch (ocurrance) {
            case (#one) slice;
            case (_) slice.slice(0, ?lastIndex); // Remove ocurrance character
        };

        return (ocurrance, trimmedSlice);
    };

    private func parseChoiceOrSequence(slice : TextSlice.TextSlice) : Result<Document.ElementChoiceOrSequence> {
        let children = Buffer.Buffer<Document.ChildElement>(5);
        let childCharacters = Buffer.Buffer<Char>(5);
        var depth = 0;
        var isChoice : ?Bool = null;
        label f for (c in slice.toIter()) {
            let addCharacter : Bool = if (c == '(') {
                depth := depth + 1;
                depth != 1; // Only add the character if we're not at the top level
            } else if (c == ')') {
                depth := depth - 1;
                depth != 0; // Only add the character if we're not at the top level
            } else if ((c == '|' or c == ',') and depth <= 1) {
                let hasChoiceSeperator = c == '|';
                if (isChoice == null) {
                    isChoice := ?hasChoiceSeperator;
                } else if (isChoice != ?hasChoiceSeperator) {
                    return #error("Cannot mix '|' and ',' in a single element");
                };
                switch (parseChildElement(TextSlice.slice(#buffer(childCharacters), 0, null))) {
                    case (#error(e)) return #error(e);
                    case (#ok(c)) children.add(c);
                };
                childCharacters.clear();
                false; // Skip seperator
            } else {
                true;
            };
            if (addCharacter) {
                childCharacters.add(c);
            };
        };
        switch (parseChildElement(TextSlice.slice(#buffer(childCharacters), 0, null))) {
            case (#error(e)) return #error(e);
            case (#ok(c)) children.add(c);
        };
        let childrenArray = Buffer.toArray(children);
        // Default to sequence unless there was a '|'
        if (isChoice == ?true) {
            #ok(#choice(childrenArray));
        } else {
            #ok(#sequence(childrenArray));
        };
    };

    private func parseAttribute(slice : TextSlice.TextSlice) : Result<Document.InternalDocumentTypeDefinition> {

        let iter = TagTokenIterator(slice);
        let elementName = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (? #error(e)) return #error(e);
            case (? #ok(t)) t.toText();
        };

        let attributeName = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (? #error(e)) return #error(e);
            case (? #ok(t)) t.toText();
        };

        let type_ : Document.AttributeType = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (? #error(e)) return #error(e);
            case (? #ok(t)) {
                if (t.get(0) == '(' and t.get(t.size() - 1) == ')') {
                    let enumValues = t.slice(1, ?(t.size() - 2)).split('|');
                    #enumeration(Iter.toArray(Iter.map<TextSlice.TextSlice, Text>(enumValues, func(t) = t.toText())));
                } else {
                    switch (t.toText()) {
                        case ("CDATA") #cdata;
                        case ("ID") #id;
                        case ("IDREF") #idRef;
                        case ("IDREFS") #idRefs;
                        case ("ENTITY") #entity;
                        case ("ENTITIES") #entities;
                        case ("NMTOKEN") #nmToken;
                        case ("NMTOKENS") #nmTokens;
                        case ("NOTATION") {
                            let notations = switch (iter.next()) {
                                case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                                case (? #error(e)) return #error(e);
                                case (? #ok(t)) t.slice(1, ?(t.size() - 2)).split('|');
                            };
                            #notation(Iter.toArray(Iter.map<TextSlice.TextSlice, Text>(notations, func(t) = t.toText())));
                        };
                        case (c) return #error("Unexpected token '" # c # "'. Expected a valid attribute type.");
                    };
                };
            };
        };

        let defaultValue = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (? #error(e)) return #error(e);
            case (? #ok(t)) switch (t.toText()) {
                case ("#REQUIRED") #required;
                case ("#IMPLIED") #implied;
                case ("#FIXED") {
                    let fixedValue = switch (iter.next()) {
                        case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                        case (? #error(e)) return #error(e);
                        case (? #ok(t)) t.trimSingle('\"').toText();
                    };
                    #fixed(fixedValue);
                };
                case (c) return #error("Unexpected token '" # c # "'. Expected '#REQUIRED', '#IMPLIED', or '#FIXED'");
            };
        };

        #ok(
            #attribute({
                name = attributeName;
                type_ = type_;
                defaultValue = defaultValue;
                elementName = elementName;
            })
        );
    };

    private func parseNotation(slice : TextSlice.TextSlice) : Result<Document.InternalDocumentTypeDefinition> {
        let iter = TagTokenIterator(slice);
        let name = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (? #error(e)) return #error(e);
            case (? #ok(t)) t.toText();
        };
        let type_ = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (? #error(e)) return #error(e);
            case (? #ok(t)) {
                switch (t.toText()) {
                    case ("PUBLIC") {
                        let id = switch (iter.next()) {
                            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                            case (? #error(e)) return #error(e);
                            case (? #ok(t)) t.trimSingle('\"').toText();
                        };
                        let url = switch (iter.next()) {
                            case (null) null;
                            case (? #error(e)) return #error(e);
                            case (? #ok(t)) ?t.trimSingle('\"').toText();
                        };
                        #public_({ id = id; url = url });
                    };
                    case ("SYSTEM") {
                        let url = switch (iter.next()) {
                            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                            case (? #error(e)) return #error(e);
                            case (? #ok(t)) t.trimSingle('\"').toText();
                        };
                        #system_({ url = url });
                    };
                    case (c) return #error("Unexpected token '" # c # "'. Expected 'PUBLIC' or 'SYSTEM'.");
                };
            };
        };

        #ok(
            #notation({
                name = name;
                type_ = type_;
            })
        );
    };

    private func parseEndTag(slice : TextSlice.TextSlice) : Result<Token.Token> {
        // TODO validate only name and no attributes
        #ok(#endTag({ name = slice.trimWhitespace().toText() }));
    };

    private func parseComment(slice : TextSlice.TextSlice) : Result<{ #comment : Text }> {
        #ok(#comment(slice.toText()));
    };

    private func parseCDATA(slice : TextSlice.TextSlice) : Result<Token.Token> {
        #ok(#cdata(slice.toText()));
    };

    private func parseStartTag(slice : TextSlice.TextSlice) : Result<Token.Token> {
        let (trimmedSlice : TextSlice.TextSlice, isSelfClosing : Bool) = switch (slice.get(slice.size() - 1)) {
            case ('/') (slice.slice(0, ?(slice.size() - 1)), true); // Started with a slash, so it's self closing, trim
            case (_) (slice, false); // No slash, so it's not self closing, no trim
        };

        let tagInfo : Token.TagInfo = switch (getTagInfo(trimmedSlice)) {
            case (#error(e)) return #error(e);
            case (#ok(t)) t;
        };

        #ok(#startTag({ tagInfo with selfClosing = isSelfClosing }));
    };

    private func parseQ(slice : TextSlice.TextSlice) : Result<Token.Token> {
        let tagInfo : Token.TagInfo = switch (getTagInfo(slice)) {
            case (#error(e)) return #error(e);
            case (#ok(t)) t;
        };
        let token = switch (TextX.toLower(tagInfo.name)) {
            case "xml" {
                var encoding : ?Text = null;
                var major : Nat = 1;
                var minor : Nat = 0;
                var standalone : ?Bool = null;
                for (attr in Iter.fromArray(tagInfo.attributes)) {
                    switch (TextX.toLower(attr.name)) {
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
                                case (?major) switch (NatX.fromText(major)) {
                                    case (null) return #error("Invalid version number '" # versionString # "'");
                                    case (?m) m;
                                };
                            };
                            minor := switch (versionComponents.next()) {
                                case (null) 0; // Skip, use default
                                case (?minor) switch (NatX.fromText(minor)) {
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
        #ok(token);
    };

    public func skipWhitespace(reader : IterX.IterReader<Char>) : () {
        loop {
            switch (isNextWhitespace(reader)) {
                case (?true) {
                    let _ = reader.next(); // Skip whitespace
                };
                case (_) {
                    return;
                };
            };
        };
    };

    private func isNextWhitespace(reader : IterX.IterReader<Char>) : ?Bool {
        do ? {
            let nextT = reader.peek()!;
            Char.isWhitespace(nextT);
        };
    };

    public type SliceParser<T> = TextSlice.TextSlice -> Result<T>;

    public type SliceMatchInfo<T> = {
        startsWith : TextSlice.TextSlice;
        endsWith : {
            #text : TextSlice.TextSlice;
            #custom : Iter.Iter<Char> -> ?(slice : TextSlice.TextSlice, suffixLength : Nat);
        };
        parse : SliceParser<T>;
    };

    public func matchAndParseSlice<T>(reader : IterX.IterReader<Char>, cases : [SliceMatchInfo<T>]) : Result<T> {
        let readCharacters = Buffer.Buffer<Char>(5);
        var charIndex = 0;
        let reIter = {
            next : () -> ?Char = func() : ?Char {
                if (charIndex >= readCharacters.size()) {
                    switch (reader.next()) {
                        case (null) return null;
                        case (?next) {
                            readCharacters.add(next);
                            charIndex += 1;
                            ?next;
                        };
                    };
                } else {
                    let c = readCharacters.get(charIndex);
                    charIndex += 1;
                    ?c;
                };
            };
            reset : () -> () = func() : () {
                charIndex := 0;
            };
        };

        // Loop through cases and check if the startsWith matches
        for (c in Iter.fromArray(cases)) {
            switch (isMatch(c.startsWith, reIter)) {
                case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                case (?false) {
                    reIter.reset(); // No match, try next case
                };
                case (?true) {
                    // Match found, parse the rest
                    reIter.reset(); // Reset the iterator
                    let (slice : TextSlice.TextSlice, suffixLength : Nat) = switch (c.endsWith) {
                        case (#text(suffix)) {
                            // Read until suffix
                            let slice = switch (readUntilSuffix(suffix, reIter)) {
                                case (null) {
                                    // No match found
                                    return #error(UNEXPECTED_ERROR_MESSAGE);
                                };
                                case (?s) (s, suffix.size());
                            };
                        };
                        case (#custom(customReader)) {
                            // Read until customReader returns a match
                            switch (customReader(reIter)) {
                                case (null) {
                                    // No match found
                                    return #error(UNEXPECTED_ERROR_MESSAGE);
                                };
                                case (?s) s;
                            };
                        };
                    };
                    // Match found, trim matches
                    let length : Nat = slice.size() - suffixLength - c.startsWith.size();
                    return c.parse(slice.slice(c.startsWith.size(), ?length));

                };
            };
        };
        return #error("No match found for '" # Text.fromIter(readCharacters.vals()) # "'");
    };

    private func readUntilSuffix(suffix : TextSlice.TextSlice, iter : Iter.Iter<Char>) : ?TextSlice.TextSlice {
        do ? {
            let buffer = Buffer.Buffer<Char>(5);
            var suffixIndex = 0;
            loop {
                let next = iter.next()!;
                buffer.add(next);
                if (next == suffix.get(suffixIndex)) {
                    suffixIndex += 1;

                    if (suffixIndex >= suffix.size()) {
                        // Found suffix
                        return ?TextSlice.slice(#buffer(buffer), 0, null);
                    };
                } else {
                    suffixIndex := 0;
                };
            };
        };
    };
    private func isMatch(prefix : TextSlice.TextSlice, iter : Iter.Iter<Char>) : ?Bool {
        var i = 0;
        for (c in prefix.toIter()) {
            switch (iter.next()) {
                case (null) return null;
                case (?c) {
                    if (c != prefix.get(i)) {
                        return ?false;
                    };
                    i += 1;
                };
            };
        };
        return ?true;
    };

    private class TagTokenIterator(tagSlice : TextSlice.TextSlice) : Iter.Iter<Result<TextSlice.TextSlice>> {
        let trimmedTagSlice = tagSlice.trimWhitespace();
        let charIter = trimmedTagSlice.toIter();
        var lastStartIndex : Nat = 0;
        var nextIndex = 0;

        public func toReader() : IterX.IterReader<Char> {
            let restOfSlice = trimmedTagSlice.slice(lastStartIndex, null);
            return IterX.IterReader(restOfSlice.toIter());
        };
        public func next() : ?Result<TextSlice.TextSlice> {
            var inQuotes = false;

            loop {
                switch (charIter.next()) {
                    case (null) return buildSlice(false);
                    case (?c) {
                        nextIndex := nextIndex + 1;
                        if (c == '\"') {
                            inQuotes := not inQuotes;
                        } else if (c == '<' or c == '>') {
                            // Only allowed as tag start/end
                            return ? #error("Unexpected character '" # Text.fromChar(c) # "'");
                        } else {
                            if (not inQuotes) {
                                if (Char.isWhitespace(c)) {
                                    return buildSlice(true);
                                };
                            };
                        };
                    };
                };
            };
        };

        private func buildSlice(isWhitespace : Bool) : ?Result<TextSlice.TextSlice> {
            if (lastStartIndex == nextIndex) {
                // If no progress was made, we are done
                return null;
            };
            let offset = if (isWhitespace) 1 else 0; // Remove whitespace
            let result = ? #ok(trimmedTagSlice.slice(lastStartIndex, ?(nextIndex - lastStartIndex - offset)));

            lastStartIndex := nextIndex;
            result;
        };
    };
};
