import Element "Element";
import Iter "mo:core@1/Iter";
import Buffer "mo:buffer@0";
import Text "mo:core@1/Text";
import List "mo:core@1/List";
module {
  type Result<T> = { #ok : T; #err : Text };

  public func serialize(root : Element.Element) : Iter.Iter<Char> {
    let buffer = List.empty<Char>();
    serializeInternal(Buffer.fromList(buffer), root);
    return List.values(buffer);
  };

  private func serializeInternal(buffer : Buffer.Buffer<Char>, element : Element.Element) {
    buffer.write('<');
    addText(buffer, element.name, false);

    for (attr in Iter.fromArray(element.attributes)) {
      buffer.write(' ');
      addText(buffer, attr.name, false);
      buffer.write('=');
      buffer.write('\"');
      switch (attr.value) {
        case (?v) addText(buffer, v, true);
        case (null) ();
      };

      buffer.write('\"');
    };

    switch (element.children) {
      case (#selfClosing) {
        buffer.write('/');
        buffer.write('>');
      };
      case (#open(children)) {
        buffer.write('>');
        for (child in Iter.fromArray(children)) {
          switch (child) {
            case (#text(value)) addText(buffer, value, true);
            case (#element(e)) serializeInternal(buffer, e);
          };
        };
        buffer.write('<');
        buffer.write('/');
        addText(buffer, element.name, false);
        buffer.write('>');
      };
    };
  };

  private func addText(buffer : Buffer.Buffer<Char>, value : Text, escape : Bool) {
    label f for (c in value.chars()) {
      if (not escape) {
        buffer.write(c);
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
        case (null) buffer.write(c);
      };
    };
  };
};
