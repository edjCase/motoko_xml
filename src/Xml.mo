import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Utf8 "Utf8";
import Tokenizer "Tokenizer";
import Parser "Parser";
import Types "Types";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";

module {
    public func decode(bytes : Blob) : ?Types.Document {
        do ? {
            let tokens : [Types.Token] = Tokenizer.tokenizeBlob(bytes)!;
            let doc = Parser.parseDocument(Iter.fromArray(tokens))!;
            Debug.trap(debug_show (doc));
        };
    };

};
