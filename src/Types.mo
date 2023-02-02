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

    public type Version = { major : Nat; minor : Nat };

    public type XmlDeclaration = {
        version : Version;
        encoding : ?Text;
        standalone : ?Bool;
    };

    public type Token = {
        #startTag : TagInfo and { selfClosing : Bool };
        #endTag : { name : Text };
        #text : Text;
        #comment : Text;
        #xmlDeclaration : XmlDeclaration;
        #processingInstruction : ProcessingInstruction;
    };
};
