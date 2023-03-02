import Document "Document";

module {

    public type Token = {
        #startTag : StartTagInfo;
        #endTag : { name : Text };
        #text : Text;
        #comment : Text;
        #xmlDeclaration : XmlDeclaration;
        #processingInstruction : Document.ProcessingInstruction;
        #docType : Document.DocType;
    };

    public type TagInfo = {
        name : Text;
        attributes : [Document.Attribute];
    };

    public type StartTagInfo = TagInfo and { selfClosing : Bool };

    public type XmlDeclaration = {
        version : Document.Version;
        encoding : ?Text;
        standalone : ?Bool;
    };

};
