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

    public type DecodeError = Parser.ParseError or {
        #tokenizeError : Text;
    };

    public type DecodeResult = {
        #ok : Types.Document;
        #error : DecodeError;
    };

    public func decode(bytes : Blob) : DecodeResult {
        let tokens : [Types.Token] = switch (Tokenizer.tokenizeBlob(bytes)) {
            case (#error(e)) return #error(#tokenizeError(e));
            case (#ok(t)) t;
        };
        return Parser.parseDocument(Iter.fromArray(tokens));
    };

};
