module {
    public type Document = {
        version : ?Version;
        encoding : ?Text;
        standalone : ?Bool;
        root : Element;
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

    public type ElementTypeDefintion = {
        name : Text;
        allowableContents : {
            #any;
            #empty;
            #children : [];
            #mixed : [];
        };
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
        #notation;
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
            #internal : {
                value : Text;
            };
            #external : {
                type_ : { #system_; #public_ : { id : Text } };
                uri : Text;
                notation : ?Text;
            };
        };
    };

    public type ParameterEntityTypeDefinition = {
        name : Text;
        type_ : {
            #internal : {
                value : Text;
            };
            #external : {
                type_ : { #system_; #public_ : { id : Text } };
                uri : Text;
            };
        };
    };

    public type NotationTypeDefinition = {
        name : Text;
        type_ : {
            #system_ : { url : Text };
            #public_ : { id : Text; uri : ?Text };
        };
    };

    public type DocumentTypeDefinition = {
        externalTypes : ?{
            #system_ : { url : Text };
            #public_ : { name : Text; uri : ?Text };
        };
        internalTypes : [{
            #element : ElementTypeDefintion;
            #attribute : AttributeTypeDefinition;
            #generalEntity : GeneralEntityTypeDefinition;
            #parameterEntity : ParameterEntityTypeDefinition;
            #notation : NotationTypeDefinition;
            #processingInstruction : ProcessingInstruction;
            #comment : Text;
        }];
    };

    public type DocType = {
        rootElementName : Text;
        typeDefintion : DocumentTypeDefinition;
    };

    public type Token = {
        #startTag : StartTagInfo;
        #endTag : { name : Text };
        #text : Text;
        #comment : Text;
        #xmlDeclaration : XmlDeclaration;
        #processingInstruction : ProcessingInstruction;
        #doctype : DocType;
    };
};
