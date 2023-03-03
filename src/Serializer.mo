import Element "Element";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
module {
    type Result<T> = { #ok : T; #error : Text };

    public func serialize(root : Element.Element) : Iter.Iter<Char> {
        let buffer = Buffer.Buffer<Char>(100);
        serializeInternal(buffer, root);
        return buffer.vals();
    };

    private func serializeInternal(buffer : Buffer.Buffer<Char>, element : Element.Element) {
        buffer.add('<');
        addText(buffer, element.name, false);

        for (attr in Iter.fromArray(element.attributes)) {
            buffer.add(' ');
            addText(buffer, attr.name, false);
            buffer.add('=');
            buffer.add('\"');
            switch (attr.value) {
                case (?v) addText(buffer, v, true);
                case (null)();
            };

            buffer.add('\"');
        };

        switch (element.children) {
            case (#selfClosing) {
                buffer.add('/');
                buffer.add('>');
            };
            case (#open(children)) {
                buffer.add('>');
                for (child in Iter.fromArray(children)) {
                    switch (child) {
                        case (#text(value)) addText(buffer, value, true);
                        case (#element(e)) serializeInternal(buffer, e);
                    };
                };
                buffer.add('<');
                buffer.add('/');
                addText(buffer, element.name, false);
                buffer.add('>');
            };
        };
    };

    private func addText(buffer : Buffer.Buffer<Char>, value : Text, escape : Bool) {
        label f for (c in value.chars()) {
            if (not escape) {
                buffer.add(c);
                continue f;
            };
            // Escape special characters
            let escapedText : ?Text = switch (c) {
                case ('<') ?"&lt;";
                case ('>') ?"&gt;";
                case ('&') ?"&amp;";
                case ('\"') ?"&quot;";
                case ('\'') ?"&apos;";
                case (_) null;
            };
            switch (escapedText) {
                case (?t) addText(buffer, t, false);
                case (null) buffer.add(c);
            };
        };
    };
};
