/// Provides functions for serializing and deserializing XML.
///
/// Import from the xml library to use this module.
/// ```motoko name=import
/// import Xml "mo:xml/Xml";
/// ```

import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Tokenizer "Tokenizer";
import Parser "Parser";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Element "Element";
import Document "Document";
import Token "Token";
import NatX "mo:xtended-numbers/NatX";
import Char "mo:base/Char";
import Prelude "mo:base/Prelude";
import Nat32 "mo:base/Nat32";
import TrieMap "mo:base/TrieMap";
import TextX "mo:xtended-text/TextX";
import Serializer "Serializer";
import Processor "Processor";

module {

    /// Generic result type that returns a successful value or an error message
    public type Result<T> = { #ok : T; #error : Text };

    /// Deserialize XML from UTF8 bytes
    /// Can parse an XML file or a root element
    /// Does not validate the XML or handle external entities
    /// Returns an error result if the XML is invalid
    /// ```motoko include=import
    /// let xmlBytes : Iter.Iter<Nat8> = ...;
    /// switch (Xml.deserializeFromBytes(xmlBytes)) {
    ///   case (#ok(root)) ...;
    ///   case (#error(error)) Debug.trap("Failed to deserialize XML: " # error);
    /// };
    /// ```
    public func deserializeFromBytes(xmlBytes : Iter.Iter<Nat8>) : Result<Element.Element> {
        let tokenizeResult = Tokenizer.tokenize(TextX.fromUtf8Bytes(xmlBytes));
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
    ///   case (#error(error)) Debug.trap("Failed to deserialize XML: " # error);
    /// };
    /// ```
    public func deserialize(xml : Iter.Iter<Char>) : Result<Element.Element> {
        let tokenizeResult = Tokenizer.tokenize(xml);
        decodeInternal(tokenizeResult);
    };

    /// Serialize an Xml Element to UTF8 bytes
    /// Does not format the XML, but does escape special characters
    /// ```motoko include=import
    /// let element : Element.Element = ...;
    /// let xmlBytes : Iter.Iter<Nat8> = Xml.serializeToBytes(element);
    /// ```
    public func serializeToBytes(root : Element.Element) : Iter.Iter<Nat8> {
        TextX.toUtf8Bytes(serialize(root));
    };

    /// Serialize an Xml Element to text
    /// Does not format the XML, but does escape special characters
    /// ```motoko include=import
    /// let element : Element.Element = ...;
    /// let xmlBytes : Iter.Iter<Nat8> = Xml.serializeToBytes(element);
    /// ```
    public func serialize(root : Element.Element) : Iter.Iter<Char> {
        Serializer.serialize(root);
    };

    private func decodeInternal(tokenizeResult : Result<[Token.Token]>) : Result<Element.Element> {
        let tokens : [Token.Token] = switch (tokenizeResult) {
            case (#error(e)) return #error("Tokenizer error: " # e);
            case (#ok(t)) t;
        };
        let doc = switch (Parser.parseDocument(Iter.fromArray(tokens))) {
            case (#error(e)) {
                let message = switch (e) {
                    case (#unexpectedToken(t)) "Unexpected token '" # debug_show (t) # "'";
                    case (#unexpectedEndOfTokens) "Unexpected end of input";
                    case (#tokensAfterRoot) "Tokens are not allowed after the root element";
                };
                return #error("Parser error: " # message);
            };
            case (#ok(d)) d;
        };
        Processor.processDocument(doc);
    };
};
