module {
    public type Element = {
        name : Text;
        attributes : [Attribute];
        children : [ElementChild];
    };

    public type ElementChild = {
        #element : Element;
        #text : Text;
    };

    public type Attribute = {
        name : Text;
        value : ?Text;
    };
};
