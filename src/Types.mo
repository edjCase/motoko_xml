module {
    public type Document = {
        version : ?Version;
        encoding : ?Text;
        standalone : ?Bool;
        root : Element;
        docType : ?DocType;
        processInstructions : [ProcessingInstruction];
    };

    public type ProcessingInstruction = {
        target : Text;
        attributes : [Attribute];
    };

    public type ElementChild = {
        #element : Element;
        #text : Text;
        #comment : Text;
    };

    public type Element = {
        name : Text;
        attributes : [Attribute];
        children : {
            #selfClosing;
            #open : [ElementChild];
        };
    };

    public type Attribute = {
        name : Text;
        value : ?Text;
    };

    public type TagInfo = {
        name : Text;
        attributes : [Attribute];
    };

    public type StartTagInfo = TagInfo and { selfClosing : Bool };

    public type Version = { major : Nat; minor : Nat };

    public type XmlDeclaration = {
        version : Version;
        encoding : ?Text;
        standalone : ?Bool;
    };

    public type ElementChoiceOrSequence = {
        #sequence : [ChildElement];
        #choice : [ChildElement];
    };

    public type Ocurrance = {
        #one;
        #zeroOrOne;
        #zeroOrMore;
        #oneOrMore;
    };

    public type ChildElement = {
        kind : ElementChoiceOrSequence or { #element : Text };
        ocurrance : Ocurrance;
    };

    public type AllowableContents = {
        #any;
        #empty;
        #children : ElementChoiceOrSequence;
        #mixed : ElementChoiceOrSequence;
    };

    public type ElementTypeDefintion = {
        name : Text;
        allowableContents : AllowableContents;
    };

    public type AttributeType = {
        #cdata;
        #id;
        #idRef;
        #idRefs;
        #entity;
        #entities;
        #nmToken;
        #nmTokens;
        #notation : [Text];
        #enumeration : [Text];
    };

    public type AttributeTypeDefinition = {
        elementName : Text;
        name : Text;
        type_ : AttributeType;
        defaultValue : { #required; #implied; #fixed : Text };
    };

    public type GeneralEntityTypeDefinition = {
        name : Text;
        type_ : {
            #internal : Text;
            #external : {
                type_ : { #system_; #public_ : { id : Text } };
                url : Text;
                notationId : ?Text;
            };
        };
    };

    public type ParameterEntityTypeDefinition = {
        name : Text;
        type_ : {
            #internal : Text;
            #external : {
                type_ : { #system_; #public_ : { id : Text } };
                url : Text;
            };
        };
    };

    public type NotationTypeDefinition = {
        name : Text;
        type_ : {
            #system_ : { url : Text };
            #public_ : { id : Text; url : ?Text };
        };
    };

    public type InternalDocumentTypeDefinition = {
        #element : ElementTypeDefintion;
        #attribute : AttributeTypeDefinition;
        #generalEntity : GeneralEntityTypeDefinition;
        #parameterEntity : ParameterEntityTypeDefinition;
        #notation : NotationTypeDefinition;
        #processingInstruction : ProcessingInstruction;
        #comment : Text;
    };
    public type ExternalTypesDefinition = {
        #system_ : { url : Text };
        #public_ : { id : Text; url : Text };
    };

    public type DocumentTypeDefinition = {
        externalTypes : ?ExternalTypesDefinition;
        internalTypes : [InternalDocumentTypeDefinition];
    };

    public type DocType = {
        rootElementName : Text;
        typeDefinition : DocumentTypeDefinition;
    };

    public type Token = {
        #startTag : StartTagInfo;
        #endTag : { name : Text };
        #text : Text;
        #comment : Text;
        #xmlDeclaration : XmlDeclaration;
        #processingInstruction : ProcessingInstruction;
        #docType : DocType;
    };
};
