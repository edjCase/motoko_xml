/// Provides element types for serializing and deserializing XML.
///
/// Import from the xml library to use this module.
/// ```motoko name=import
/// import Element "mo:xml/Element";
/// ```

module {

    /// An xml element type that can be serialized and deserialized
    public type Element = {
        name : Text;
        attributes : [Attribute];
        children : ElementChildren;
    };

    public type ElementChildren = {
        #selfClosing;
        #open : [ElementChild];
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
