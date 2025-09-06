/// Provides functions for serializing and deserializing XML.
///
/// Import from the xml library to use this module.
/// ```motoko name=import
/// import Xml "mo:xml";
/// ```

import Iter "mo:core@1/Iter";
import Text "mo:core@1/Text";
import Tokenizer "Tokenizer";
import Parser "Parser";
import Element "Element";
import Token "Token";
import Char "mo:core@1/Char";
import Result "mo:core@1/Result";
import Serializer "Serializer";
import Processor "Processor";
import Blob "mo:core@1/Blob";

module {

  public type Element = Element.Element;
  public type ElementChildren = Element.ElementChildren;
  public type ElementChild = Element.ElementChild;
  public type Attribute = Element.Attribute;

  /// Deserialize XML from UTF8 bytes
  /// Can parse an XML file or a root element
  /// Does not validate the XML or handle external entities
  /// Returns an error result if the XML is invalid
  /// ```motoko include=import
  /// let xmlBytes : Iter.Iter<Nat8> = ...;
  /// switch (Xml.deserializeFromBytes(xmlBytes)) {
  ///   case (#ok(root)) ...;
  ///   case (#err(error)) Runtime.trap("Failed to deserialize XML: " # error);
  /// };
  /// ```
  public func fromBytes(xmlBytes : Iter.Iter<Nat8>) : Result.Result<Element.Element, Text> {
    // TODO right now have to Iter -> Array -> Blob
    let xmlText = switch (Text.decodeUtf8(Blob.fromArray(Iter.toArray(xmlBytes)))) {
      case (null) return #err("Failed to decode XML bytes to text");
      case (?xmlText) xmlText;
    };
    let tokenizeResult = Tokenizer.tokenize(xmlText.chars());
    decodeInternal(tokenizeResult);
  };

  /// Deserialize XML from text
  /// Can parse an XML file or a root element
  /// Does not validate the XML or handle external entities
  /// Returns an error result if the XML is invalid
  /// ```motoko include=import
  /// let xmlText : Text = "<root><child>text</child></root>";
  /// switch (Xml.deserialize(xmlText.chars())) {
  ///   case (#ok(root)) ...;
  ///   case (#err(error)) Runtime.trap("Failed to deserialize XML: " # error);
  /// };
  /// ```
  public func fromText(xml : Iter.Iter<Char>) : Result.Result<Element.Element, Text> {
    let tokenizeResult = Tokenizer.tokenize(xml);
    decodeInternal(tokenizeResult);
  };

  /// Serialize an Xml Element to UTF8 bytes
  /// Does not format the XML, but does escape special characters
  /// ```motoko include=import
  /// let element : Element.Element = ...;
  /// let xmlBytes : Iter.Iter<Nat8> = Xml.serializeToBytes(element);
  /// ```
  public func toBytes(root : Element.Element) : Iter.Iter<Nat8> {
    Text.encodeUtf8(Text.fromIter(toText(root))).vals();
  };

  /// Serialize an Xml Element to text
  /// Does not format the XML, but does escape special characters
  /// ```motoko include=import
  /// let element : Element.Element = ...;
  /// let xmlBytes : Iter.Iter<Nat8> = Xml.serializeToBytes(element);
  /// ```
  public func toText(root : Element.Element) : Iter.Iter<Char> {
    Serializer.serialize(root);
  };

  private func decodeInternal(tokenizeResult : Result.Result<[Token.Token], Text>) : Result.Result<Element.Element, Text> {
    let tokens : [Token.Token] = switch (tokenizeResult) {
      case (#err(e)) return #err("Tokenizer error: " # e);
      case (#ok(t)) t;
    };
    let doc = switch (Parser.parseDocument(Iter.fromArray(tokens))) {
      case (#err(e)) {
        let message = switch (e) {
          case (#unexpectedToken(t)) "Unexpected token '" # debug_show (t) # "'";
          case (#unexpectedEndOfTokens) "Unexpected end of input";
          case (#tokensAfterRoot) "Tokens are not allowed after the root element";
        };
        return #err("Parser error: " # message);
      };
      case (#ok(d)) d;
    };
    Processor.processDocument(doc);
  };
};
