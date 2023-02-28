import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Char "mo:base/Char";
import Types "Types";
import Nat "mo:base/Nat";
import NatX "mo:xtended-numbers/NatX";
import Prelude "mo:base/Prelude";
import Array "mo:base/Array";
import Nat32 "mo:base/Nat32";
import TextX "TextX";
import IterX "IterX";
import TextSlice "TextSlice";
import Slice "Slice";

module {

    public let UNEXPECTED_ERROR_MESSAGE = "Unexpected end of characters";

    type Result<T> = { #ok : T; #error : Text };

    public type TokenizeResult = Result<[Types.Token]>;

    public func tokenizeText(value : Text) : TokenizeResult {
        let reader = IterX.IterReader<Char>(Text.toIter(value));
        return tokenize(reader);
    };

    public func tokenizeBlob(value : Blob) : TokenizeResult {
        let reader = IterX.IterReader<Char>(TextX.fromUtf8Bytes(value.vals()));
        return tokenize(reader);
    };

    public func tokenizeBytes(value : [Nat8]) : TokenizeResult {
        let reader = IterX.IterReader<Char>(TextX.fromUtf8Bytes(value.vals()));
        return tokenize(reader);
    };

    public func tokenize(reader : IterX.IterReader<Char>) : TokenizeResult {
        let tokenBuffer = Buffer.Buffer<Types.Token>(2);
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

    private func getNext(reader : IterX.IterReader<Char>) : Result<Types.Token> or {
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
                            let textValue = switch (decodeTextValue(charBuffer)) {
                                case (#error(e)) return #error(e);
                                case (#ok(v)) v;
                            };
                            #text(textValue);
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
                            case (_)(); // Skip
                        };
                        charBuffer.add(c);
                        let _ = reader.next();
                    };
                };
            };
        };
    };

    private func decodeTextValue(buffer : Buffer.Buffer<Char>) : Result<Text> {
        let decodedTexcharBuffer = Buffer.Buffer<Char>(buffer.size());
        let referenceValueBuffer = Buffer.Buffer<Char>(4);
        var inAmp = false;
        for (c in buffer.vals()) {
            // If characters are between & and ; then they are a reference
            // to a value. This does the translation if it can
            if (inAmp) {
                if (c == ';') {
                    inAmp := false;
                    // Decode the value and write it to the text buffer
                    switch (writeEntityValue(referenceValueBuffer, decodedTexcharBuffer)) {
                        case (#ok)();
                        case (#error(e)) return #error(e);
                    };
                    // Clear character buffer and continue iterating
                    referenceValueBuffer.clear();
                } else {
                    // Add to the character buffer if between & and ;
                    referenceValueBuffer.add(c);
                };
            } else {
                if (c == '&') {
                    inAmp := true;
                } else {
                    // Add regular character
                    decodedTexcharBuffer.add(c);
                };
            };
        };
        if (inAmp) {
            return #error("Unexpected character '&'");
        };
        #ok(Text.fromIter(decodedTexcharBuffer.vals()));
    };

    private func writeEntityValue(escapedValue : Buffer.Buffer<Char>, decodedTexcharBuffer : Buffer.Buffer<Char>) : Result<()> {
        // If starts with a #, its a unicode character
        switch (escapedValue.get(0)) {
            case ('#') {
                // # means its a unicode value
                let unicodeScalar : ?Nat = if (escapedValue.get(1) == 'x') {
                    // If prefixed with x, it is a hex value
                    let hexBuffer = Buffer.subBuffer<Char>(escapedValue, 2, escapedValue.size() - 2);
                    let hex = Text.fromIter(hexBuffer.vals());
                    NatX.fromTextAdvanced(hex, #hexadecimal, null); // Parse hexadecimal
                } else {
                    // Otherwise its a decimal value
                    let decimalBuffer = Buffer.subBuffer<Char>(escapedValue, 1, escapedValue.size() - 1);
                    let decimal = Text.fromIter(decimalBuffer.vals());
                    NatX.fromText(decimal); // Parse decimal
                };
                switch (unicodeScalar) {
                    case (null) return #error("Invalid unicode value '" # Text.fromIter(escapedValue.vals()) # "'");
                    case (?s) {
                        // Must fit in a nat32
                        if (s > 4294967295) {
                            return #error("Invalid unicode value '" # Text.fromIter(escapedValue.vals()) # "'");
                        };
                        // Convert unicode id to a unicode character
                        let unicodeCharacter = Char.fromNat32(Nat32.fromNat(s));
                        decodedTexcharBuffer.add(unicodeCharacter);
                        #ok;
                    };
                };
            };
            case ('%') {
                Prelude.nyi(); // TODO parameters?
            };
            case (_) {
                let c = switch (Text.fromIter(escapedValue.vals())) {
                    case ("lt") '<';
                    case ("gt") '>';
                    case ("apos") '\'';
                    case ("quot") '\u{22}';
                    case ("amp") '&';
                    case (entityId) {
                        // TODO custom entities. This just returns the original value
                        decodedTexcharBuffer.add('&');
                        decodedTexcharBuffer.append(escapedValue);
                        decodedTexcharBuffer.add(';');
                        return #ok;
                    };
                };
                decodedTexcharBuffer.add(c);
                #ok;
            };
        };
    };

    private func getTagInfo(tag : TextSlice.TextSlice) : Result<Types.TagInfo> {
        let tagTokens : Iter.Iter<Result<TextSlice.TextSlice>> = TagTokenIterator(tag);

        let name : TextSlice.TextSlice = switch (tagTokens.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (?t) switch (t) {
                case (#error(e)) return #error(e);
                case (#ok(t)) t;
            };
        };

        let attributes = Buffer.Buffer<Types.Attribute>(0);

        label l loop {
            let attribute = switch (tagTokens.next()) {
                case (null) {
                    break l;
                };
                case (?#error(e)) {
                    return #error(e);
                };
                case (?#ok(t)) {
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
                let value = slice.slice(index + 1, null).trimSingle('\u{22}'); // Remove quotes. '\u{22}' instead of '\"'. There is a parsing bug

                ?(name.toText(), ?value.toText());
            };
        };
    };

    private func parseTagToken(reader : IterX.IterReader<Char>) : Result<Types.Token> {
        matchAndParseSlice(
            reader,
            [
                {
                    startsWith = TextSlice.fromText("</");
                    endsWith = TextSlice.fromText(">");
                    parse = parseEndTag;
                },
                {
                    startsWith = TextSlice.fromText("<!--");
                    endsWith = TextSlice.fromText("-->");
                    parse = parseComment;
                },
                {
                    startsWith = TextSlice.fromText("<?");
                    endsWith = TextSlice.fromText("?>");
                    parse = parseQ;
                },
                {
                    startsWith = TextSlice.fromText("<![CDATA[");
                    endsWith = TextSlice.fromText("]]>");
                    parse = parseCDATA;
                },
                {
                    startsWith = TextSlice.fromText("<!DOCTYPE");
                    endsWith = TextSlice.fromText(">");
                    parse = parseDocType;
                },
                {
                    startsWith = TextSlice.fromText("<");
                    endsWith = TextSlice.fromText(">");
                    parse = parseStartTag;
                },
            ],
        );
    };

    private func parseDocType(slice : TextSlice.TextSlice) : Result<Types.Token> {
        let iter = TagTokenIterator(slice);
        let rootElementName : Text = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (?#error(e)) return #error(e);
            case (?#ok(t)) t.toText();
        };
        let (externalTypes : ?Types.ExternalTypesDefinition, internalTypes : [Types.InternalDocumentTypeDefinition]) = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (?#error(e)) return #error(e);
            case (?#ok(t)) {
                switch (TextX.toUpper(t.toText())) {
                    case ("PUBLIC") {
                        let publicId = switch (iter.next()) {
                            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                            case (?#error(e)) return #error(e);
                            case (?#ok(t)) t.toText();
                        };
                        let url = switch (iter.next()) {
                            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                            case (?#error(e)) return #error(e);
                            case (?#ok(t)) t.toText();
                        };
                        let externalTypes : ?Types.ExternalTypesDefinition = ?#public_({
                            id = publicId;
                            url = url;
                        });
                        let internalTypes : [Types.InternalDocumentTypeDefinition] = switch (parseInternalTypes(iter)) {
                            case (#error(e)) return #error(e);
                            case (#ok(t)) t;
                        };
                        (externalTypes, internalTypes);
                    };
                    case ("SYSTEM") {
                        let url = switch (iter.next()) {
                            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                            case (?#error(e)) return #error(e);
                            case (?#ok(t)) t;
                        };
                        let externalTypes : ?Types.ExternalTypesDefinition = ?#system_({
                            url = url.toText();
                        });
                        let internalTypes : [Types.InternalDocumentTypeDefinition] = switch (parseInternalTypes(iter)) {
                            case (#error(e)) return #error(e);
                            case (#ok(t)) t;
                        };
                        (externalTypes, internalTypes);
                    };
                    case ("[") {
                        let externalTypes : ?Types.ExternalTypesDefinition = null;
                        let internalTypes : [Types.InternalDocumentTypeDefinition] = switch (parseInternalTypes(iter)) {
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
            }),
        );
    };

    private func parseInternalTypes(iter : TagTokenIterator) : Result<[Types.InternalDocumentTypeDefinition]> {
        let internalTypes = Buffer.Buffer<Types.InternalDocumentTypeDefinition>(2);
        label l loop {
            let internalType = switch (iter.next()) {
                case (null) {
                    break l;
                };
                case (?#error(e)) {
                    return #error(e);
                };
                case (?#ok(t)) {
                    if (t.size() == 1) {
                        let char = t.get(0);
                        if (char == ']') {
                            break l; // End of internal types
                        };
                        if (char == '[') {
                            if (internalTypes.size() > 0) {
                                return #error("Unexpected token '['");
                            };
                            continue l; // Skip first bracket
                        };
                    };
                    switch (parseInternalType(t)) {
                        case (#error(e)) return #error(e);
                        case (#ok(t)) t;
                    };
                };
            };
            internalTypes.add(internalType);
        };
        #ok(Buffer.toArray(internalTypes));
    };

    private func parseInternalType(slice : TextSlice.TextSlice) : Result<Types.InternalDocumentTypeDefinition> {
        let firstSpaceIndex : Nat = switch (slice.indexOf(' ')) {
            case (null) return #error("Invalid tag '" # slice.toText() # "'");
            case (?i) i;
        };
        let typeDefName = slice.slice(0, ?firstSpaceIndex).trimWhitespace().toText();
        let internalTypeParser : TextSlice.TextSlice -> Result<Types.InternalDocumentTypeDefinition> = switch (TextX.toUpper(typeDefName)) {
            case ("ENTITY") parseEntity;
            case ("ELEMENT") parseElement;
            case ("ATTLIST") parseAttribute;
            case ("NOTATION") parseNotation;
            case (t) return #error("Unknown type definition '" # t # "'");
        };
        internalTypeParser(slice.slice(firstSpaceIndex, null));
    };

    private func parseEntity(slice : TextSlice.TextSlice) : Result<Types.InternalDocumentTypeDefinition> {
        let iter = TagTokenIterator(slice);
        let nameOrPercent = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (?#error(e)) return #error(e);
            case (?#ok(t)) t;
        };

        let token : Types.InternalDocumentTypeDefinition = if (nameOrPercent.size() == 1 and nameOrPercent.get(0) == '%') {
            let name = switch (iter.next()) {
                case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                case (?#error(e)) return #error(e);
                case (?#ok(t)) t.toText();
            };
            let kind = switch (iter.next()) {
                case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                case (?#error(e)) return #error(e);
                case (?#ok(t)) t.toText();
            };
            let type_ = switch (kind) {
                case ("SYSTEM") {
                    let url = switch (iter.next()) {
                        case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                        case (?#error(e)) return #error(e);
                        case (?#ok(t)) t.toText();
                    };
                    #external({
                        type_ = #system_;
                        url = url;
                    });
                };
                case ("PUBLIC") {
                    let publicId = switch (iter.next()) {
                        case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                        case (?#error(e)) return #error(e);
                        case (?#ok(t)) t.toText();
                    };
                    let url = switch (iter.next()) {
                        case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                        case (?#error(e)) return #error(e);
                        case (?#ok(t)) t.toText();
                    };
                    #external({
                        type_ = #public_({ id = publicId });
                        url = url;
                    });
                };
                case (entityValue) {
                    #internal({
                        value = entityValue;
                    });
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
                case (?#error(e)) return #error(e);
                case (?#ok(t)) t.toText();
            };
            let type_ = switch (kind) {
                case ("SYSTEM") {
                    let url = switch (iter.next()) {
                        case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                        case (?#error(e)) return #error(e);
                        case (?#ok(t)) t.toText();
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
                        case (?#error(e)) return #error(e);
                        case (?#ok(t)) t.toText();
                    };
                    let url = switch (iter.next()) {
                        case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                        case (?#error(e)) return #error(e);
                        case (?#ok(t)) t.toText();
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
                    #internal({
                        value = entityValue;
                    });
                };
            };
            #generalEntity({
                name = name;
                type_ = type_;
            });
        };

        switch (iter.next()) {
            case (null) return #ok(token);
            case (?#error(e)) return #error(e);
            case (?#ok(t)) return #error("Unexpected token '" # t.toText() # "'");
        };
    };

    private func parseNotationId(iter : TagTokenIterator) : Result<?Text> {
        switch (iter.next()) {
            case (null) #ok(null);
            case (?#error(e)) #error(e);
            case (?#ok(t)) {
                let ndata = t.toText();
                if (ndata != "NDATA") {
                    return #error("Unexpected token '" #ndata # "'. Expected 'NDATA'");
                };
                switch (iter.next()) {
                    case (null) #error(UNEXPECTED_ERROR_MESSAGE);
                    case (?#error(e)) #error(e);
                    case (?#ok(t)) #ok(?t.toText());
                };
            };
        };
    };

    private func parseElement(slice : TextSlice.TextSlice) : Result<Types.InternalDocumentTypeDefinition> {
        let iter = TagTokenIterator(slice);
        let name = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (?#error(e)) return #error(e);
            case (?#ok(t)) t.toText();
        };
        let allowableContents : Types.AllowableContents = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (?#error(e)) return #error(e);
            case (?#ok(childSlice)) {
                if (childSlice.get(0) != '(') {
                    switch (childSlice.toText()) {
                        case ("EMPTY") #empty;
                        case ("ANY") #any;
                        case (c) return #error("Unexpected token '" # c # "'. Expected 'EMPTY', 'ANY', or '('");
                    };
                } else {

                    let child = switch (parseChildElement(childSlice)) {
                        case (#error(e)) return #error(e);
                        case (#ok(child)) child;
                    };
                    switch (child) {
                        case ({ kind = #choice(childElements); ocurrance = o }) {
                            if (childElements[0].kind == #element("#PCDATA")) {
                                // Mixed when #PCDATA is the first child
                                #mixed({
                                    kind = #choice(childElements);
                                    ocurrance = o;
                                });
                            } else {
                                #children({
                                    kind = #choice(childElements);
                                    ocurrance = o;
                                });
                            };
                        };
                        case (c) {
                            #children(c);
                        };
                    };
                };
            };
        };

        #ok(#element({ name = name; allowableContents = allowableContents }));
    };

    private func parseChildElement(childSlice : TextSlice.TextSlice) : Result<Types.ChildElement> {
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
        if (sliceWithoutOcurrance.get(lastIndex - 1) != ')') {
            // Validate it ends in a ')'
            return #error("Unexpected token '" # Text.fromChar(sliceWithoutOcurrance.get(lastIndex - 1)) # "'. Expected ')'");
        };

        let sliceWithoutParans = sliceWithoutOcurrance.slice(1, ?(lastIndex - 1)); // Remove '(' and ')'
        let kind = switch (parseChildElementKind(sliceWithoutParans)) {
            case (#error(e)) return #error(e);
            case (#ok(k)) k;
        };
        #ok({
            kind = kind;
            ocurrance = ocurrance;
        });
    };

    private func parseOcurrance(slice : TextSlice.TextSlice) : (Types.Ocurrance, TextSlice.TextSlice) {
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

    private func parseChildElementKind(childrenSlice : TextSlice.TextSlice) : Result<{ #choice : [Types.ChildElement]; #sequence : [Types.ChildElement] }> {
        let c = if (childrenSlice.indexOf('|') != null) {
            // If there's a pipe, it's a choice
            // ex: (a|b|c)*
            let children = switch (getChildren('|', childrenSlice)) {
                case (#error(e)) return #error(e);
                case (#ok(c)) c;
            };
            #choice(children);
        } else {
            // If there's no pipe, it's a sequence of one or many
            // ex: (a,b,c)*
            // ex: (a)
            let children = switch (getChildren(',', childrenSlice)) {
                case (#error(e)) return #error(e);
                case (#ok(c)) c;
            };
            #sequence(children);
        };
        #ok(c);
    };

    private func getChildren(seperator : Char, trimmedText : TextSlice.TextSlice) : Result<[Types.ChildElement]> {
        let choices = Buffer.Buffer<Types.ChildElement>(5);
        for (a in trimmedText.split('|')) {
            switch (parseChildElement(a)) {
                case (#error(e)) return #error(e);
                case (#ok(c)) choices.add(c);
            };
        };
        return #ok(Buffer.toArray(choices));
    };

    private func parseAttribute(slice : TextSlice.TextSlice) : Result<Types.InternalDocumentTypeDefinition> {
        let iter = TagTokenIterator(slice);
        let elementName = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (?#error(e)) return #error(e);
            case (?#ok(t)) t.toText();
        };

        let attributeName = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (?#error(e)) return #error(e);
            case (?#ok(t)) t.toText();
        };

        let type_ : Types.AttributeType = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (?#error(e)) return #error(e);
            case (?#ok(t)) {
                if (t.get(0) == '(' and t.get(t.size() - 1) == ')') {
                    let enumValues = t.slice(1, ?(t.size() - 1)).split('|');
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
                                case (?#error(e)) return #error(e);
                                case (?#ok(t)) t.slice(1, ?(t.size() - 1)).split('|');
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
            case (?#error(e)) return #error(e);
            case (?#ok(t)) switch (t.toText()) {
                case ("#REQUIRED") #required;
                case ("#IMPLIED") #implied;
                case ("#FIXED") {
                    let fixedValue = switch (iter.next()) {
                        case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                        case (?#error(e)) return #error(e);
                        case (?#ok(t)) t.toText();
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
            }),
        );
    };

    private func parseNotation(slice : TextSlice.TextSlice) : Result<Types.InternalDocumentTypeDefinition> {
        let iter = TagTokenIterator(slice);
        let name = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (?#error(e)) return #error(e);
            case (?#ok(t)) t.toText();
        };
        let type_ = switch (iter.next()) {
            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
            case (?#error(e)) return #error(e);
            case (?#ok(t)) {
                switch (t.toText()) {
                    case ("PUBLIC") {
                        let id = switch (iter.next()) {
                            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                            case (?#error(e)) return #error(e);
                            case (?#ok(t)) t.toText();
                        };
                        let url = switch (iter.next()) {
                            case (null) null;
                            case (?#error(e)) return #error(e);
                            case (?#ok(t)) ?t.toText();
                        };
                        #public_({ id = id; url = url });
                    };
                    case ("SYSTEM") {
                        let url = switch (iter.next()) {
                            case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                            case (?#error(e)) return #error(e);
                            case (?#ok(t)) t.toText();
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
            }),
        );
    };

    private func parseEndTag(slice : TextSlice.TextSlice) : Result<Types.Token> {
        // TODO validate only name and no attributes
        #ok(#endTag({ name = slice.trimWhitespace().toText() }));
    };

    private func parseComment(slice : TextSlice.TextSlice) : Result<Types.Token> {
        #ok(#comment(slice.toText()));
    };

    private func parseCDATA(slice : TextSlice.TextSlice) : Result<Types.Token> {
        #ok(#text(slice.toText()));
    };

    private func parseStartTag(slice : TextSlice.TextSlice) : Result<Types.Token> {
        let (trimmedSlice : TextSlice.TextSlice, isSelfClosing : Bool) = switch (slice.get(slice.size() - 1)) {
            case ('/')(slice.slice(0, ?(slice.size() - 1)), true); // Started with a slash, so it's self closing, trim
            case (s)(slice, false); // No slash, so it's not self closing, no trim
        };

        let tagInfo : Types.TagInfo = switch (getTagInfo(trimmedSlice)) {
            case (#error(e)) return #error(e);
            case (#ok(t)) t;
        };

        #ok(#startTag({ tagInfo with selfClosing = isSelfClosing }));
    };

    private func parseQ(slice : TextSlice.TextSlice) : Result<Types.Token> {
        let tagInfo : Types.TagInfo = switch (getTagInfo(slice)) {
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

    public type SliceParser = TextSlice.TextSlice -> Result<Types.Token>;

    public type SliceMatchInfo = {
        startsWith : TextSlice.TextSlice;
        endsWith : TextSlice.TextSlice;
        parse : SliceParser;
    };

    public func matchAndParseSlice(reader : IterX.IterReader<Char>, cases : [SliceMatchInfo]) : Result<Types.Token> {
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
        let matches : Bool = false;
        var caseIndex : Nat = 0;
        for (c in Iter.fromArray(cases)) {
            switch (isMatch(c.startsWith, reIter)) {
                case (null) return #error(UNEXPECTED_ERROR_MESSAGE);
                case (?false) {
                    reIter.reset(); // No match, try next case
                };
                case (?true) {
                    // Match found, parse the rest
                    reIter.reset(); // Reset the iterator
                    switch (readUntilSuffix(c.endsWith, reIter)) {
                        case (null) {
                            // Unexpected end, should have matched
                            return #error(UNEXPECTED_ERROR_MESSAGE);
                        };
                        case (?slice) {
                            // Match found, trim matches
                            return c.parse(slice.slice(c.startsWith.size(), ?(slice.size() - c.endsWith.size() - c.startsWith.size())));
                        };
                    };

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
        let charIter = tagSlice.toIter();
        var lastStartIndex : Nat = 0;
        var nextIndex = 0;

        public func next() : ?Result<TextSlice.TextSlice> {
            var inQuotes = false;

            loop {
                switch (charIter.next()) {
                    case (null) return buildSlice(false);
                    case (?c) {
                        nextIndex := nextIndex + 1;
                        // '\u{22}' instead of '\"'. There is a parsing bug
                        if (c == '\u{22}') {
                            inQuotes := not inQuotes;
                        } else if (c == '<' or c == '>') {
                            // Only allowed as tag start/end
                            return ?#error("Unexpected character '" # Text.fromChar(c) # "'");
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
                return null;
            };
            let offset = if (isWhitespace) 1 else 0; // Remove whitespace
            let result = ?#ok(tagSlice.slice(lastStartIndex, ?(nextIndex - lastStartIndex - offset)));

            lastStartIndex := nextIndex;
            result;
        };
    };
};
