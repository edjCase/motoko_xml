import Document "Document";
import Element "Element";
import Text "mo:core@1/Text";
import NatX "mo:xtended-numbers@2/NatX";
import Iter "mo:core@1/Iter";
import Char "mo:core@1/Char";
import Nat32 "mo:core@1/Nat32";
import Result "mo:core@1/Result";
import Map "mo:core@1/Map";
import List "mo:core@1/List";

module {

  public func processDocument(document : Document.Document) : Result.Result<Element.Element, Text> {
    let defaultEntries = Iter.fromArray([
      ("amp", "&"),
      ("apos", "'"),
      ("gt", ">"),
      ("lt", "<"),
      ("quot", "\""),
    ]);
    let entityMap = Map.fromIter<Text, Text>(defaultEntries, Text.compare);
    addEntities(document.docType, entityMap);
    processElement(document.root, entityMap);
  };

  private func addEntities(docType : ?Document.DocType, entityMap : Map.Map<Text, Text>) {
    switch (docType) {
      case (null) ();
      case (?d) {
        let paramerterEntityMap = Map.empty<Text, Text>();
        // Add any parameter entities first, to potentially replace the entity values
        for (internalType in Iter.fromArray(d.typeDefinition.internalTypes)) {
          switch (internalType) {
            case (#parameterEntity({ name = n; type_ = #internal(v) })) {
              Map.add(paramerterEntityMap, Text.compare, "%" # n, v);
            };
            case (_) ();
          };
        };
        // Add any general entity values
        for (internalType in Iter.fromArray(d.typeDefinition.internalTypes)) {
          switch (internalType) {
            case (#generalEntity({ name = n; type_ = #internal(v) })) {
              let realV = switch (Map.get(paramerterEntityMap, Text.compare, v)) {
                case (null) v; // If not found, use the value as is
                case (?parameterV) parameterV; // Replace with parameter value
              };
              Map.add(entityMap, Text.compare, n, realV);
            };
            case (_) ();
          };
        };
      };
    };
  };

  private func processElement(element : Document.Element, entityMap : Map.Map<Text, Text>) : Result.Result<Element.Element, Text> {
    let children : Element.ElementChildren = switch (element.children) {
      case (#open(children)) {
        let childrenBuffer = List.empty<Element.ElementChild>();
        for (child in Iter.fromArray(children)) {
          switch (processElementChild(child, entityMap)) {
            case (#err(e)) return #err(e);
            case (#ok(null)) (); // Skip (comments)
            case (#ok(?c)) List.add(childrenBuffer, c);
          };
        };
        #open(List.toArray(childrenBuffer));
      };
      case (#selfClosing) #selfClosing;
    };

    #ok({
      name = element.name;
      attributes = element.attributes;
      children = children;
    });
  };

  private func processElementChild(
    child : Document.ElementChild,
    entityMap : Map.Map<Text, Text>,
  ) : Result.Result<?Element.ElementChild, Text> {
    let processedChild = switch (child) {
      case (#element(e)) {
        switch (processElement(e, entityMap)) {
          case (#err(e)) return #err(e);
          case (#ok(e)) ?#element(e);
        };
      };
      case (#text(t)) {
        switch (processText(t, entityMap)) {
          case (#err(e)) return #err(e);
          case (#ok(t)) ?#text(t);
        };
      };
      case (#comment(_)) null;
      case (#cdata(c)) ?#text(c); // Dont process CDATA
    };
    #ok(processedChild);
  };

  private func processText(text : Text, entityMap : Map.Map<Text, Text>) : Result.Result<Text, Text> {
    let decodedTexcharBuffer = List.empty<Char>();
    let referenceValueBuffer = List.empty<Char>();
    var inAmp = false;
    for (c in text.chars()) {
      // If characters are between & and ; then they are a reference
      // to a value. This does the translation if it can
      if (inAmp) {
        if (c == ';') {
          inAmp := false;
          // Decode the value and write it to the text buffer
          switch (writeEntityValue(referenceValueBuffer, decodedTexcharBuffer, entityMap)) {
            case (#ok) ();
            case (#err(e)) return #err(e);
          };
          // Clear character buffer and continue iterating
          List.clear(referenceValueBuffer);
        } else {
          // Add to the character buffer if between & and ;
          List.add(referenceValueBuffer, c);
        };
      } else {
        if (c == '&') {
          inAmp := true;
        } else {
          // Add regular character
          List.add(decodedTexcharBuffer, c);
        };
      };
    };
    if (inAmp) {
      return #err("Unexpected character '&'");
    };
    #ok(Text.fromIter(List.values(decodedTexcharBuffer)));
  };

  private func writeEntityValue(
    escapedValue : List.List<Char>,
    decodedTexcharBuffer : List.List<Char>,
    entityMap : Map.Map<Text, Text>,
  ) : Result.Result<(), Text> {
    // If starts with a #, its a unicode character
    switch (List.at(escapedValue, 0)) {
      case ('#') {
        // # means its a unicode value
        let unicodeScalar : ?Nat = if (List.at(escapedValue, 1) == 'x') {
          // If prefixed with x, it is a hex value
          let hex = List.values(escapedValue)
          |> Iter.drop(_, 2) // Drop the #x
          |> Text.fromIter(_);
          NatX.fromTextAdvanced(hex, #hexadecimal, null); // Parse hexadecimal
        } else {
          // Otherwise its a decimal value
          let decimal = List.values(escapedValue)
          |> Iter.drop(_, 1) // Drop the #
          |> Text.fromIter(_);
          NatX.fromText(decimal); // Parse decimal
        };
        switch (unicodeScalar) {
          case (null) return #err("Invalid unicode value '" # Text.fromIter(List.values(escapedValue)) # "'");
          case (?s) {
            // Must fit in a nat32
            if (s > 4294967295) {
              return #err("Invalid unicode value '" # Text.fromIter(List.values(escapedValue)) # "'");
            };
            // Convert unicode id to a unicode character
            let unicodeCharacter = Char.fromNat32(Nat32.fromNat(s));
            List.add(decodedTexcharBuffer, unicodeCharacter);
            #ok;
          };
        };
      };
      case (_) {
        switch (Map.get(entityMap, Text.compare, Text.fromIter(List.values(escapedValue)))) {
          case (null) {
            // Could not find the entity. This just returns the original value
            List.add(decodedTexcharBuffer, '&');
            List.addAll(decodedTexcharBuffer, List.values(escapedValue));
            List.add(decodedTexcharBuffer, ';');
          };
          case (?replacement) {
            for (c in replacement.chars()) {
              List.add(decodedTexcharBuffer, c);
            };
          };
        };
        #ok;
      };
    };
  };

};
