module {
    public type Document = {
        version : Text;
        encoding : Text;
        elements : [Element];
    };

    public type Element = {
        name : Text;
        attributes : [Attribute];
        children : {
            #selfClosing;
            #open : [{
                #element : Element;
                #text : Text;
                #comment : Text;
            }];
        };
    };

    public type Attribute = {
        name : Text;
        value : ?Text;
    };
};
