import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Char "mo:base/Char";
import NatX "mo:xtended-numbers/NatX";
import Debug "mo:base/Debug";
import Slice "Slice";
import Array "mo:base/Array";
import CharX "CharX";

module TextX {
    public func toLower(text : Text) : Text {
        let buffer = Buffer.Buffer<Char>(text.size());
        for (char in text.chars()) {
            buffer.add(CharX.toLower(char));
        };
        return Text.fromIter(buffer.vals());
    };

    public func toUpper(text : Text) : Text {
        let buffer = Buffer.Buffer<Char>(text.size());
        for (char in text.chars()) {
            buffer.add(CharX.toUpper(char));
        };
        return Text.fromIter(buffer.vals());
    };

    public func fromUtf8Bytes(bytes : Iter.Iter<Nat8>) : Iter.Iter<Char> {
        return Utf8Iter(bytes);
    };

    private class Utf8Iter(bytes : Iter.Iter<Nat8>) : Iter.Iter<Char> {
        private func nextNat32(isSubByte : Bool) : ?Nat32 {
            do ? {
                let byte = bytes.next()!;
                if (isSubByte) {
                    // Check for `10` prefix
                    if (byte & 0xC0 == 0xC0) {
                        // Remove prefix
                        return ?NatX.from8To32(byte & 0x3F);
                    };
                    // Invalid sub byte
                    return null;
                };
                NatX.from8To32(byte);
            };
        };

        public func next() : ?Char {
            do ? {
                loop {
                    let byte1 = nextNat32(false)!;
                    let nat32 = if (byte1 & 0x80 == 0) {
                        // Single byte encoding
                        // 0xxxxxxx
                        byte1 & 0x7F;
                    } else if (byte1 & 0xE0 == 0xC0) {
                        // Two bytes encoded
                        // 110xxxxx 10xxxxxx
                        let byte2 = nextNat32(true)!;
                        (byte1 & 0x1F) << 6 & byte2;
                    } else if (byte1 & 0xF0 == 0xE0) {
                        // Three bytes encoded
                        // 1110xxxx 10xxxxxx 10xxxxxx
                        let byte2 = nextNat32(true)!;
                        let byte3 = nextNat32(true)!;
                        ((byte1 & 0x0F) << 12) & (byte2 << 6) & byte3;
                    } else if (byte1 & 0xF8 == 0xF0) {
                        // Four bytes encoded
                        // 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
                        let byte2 = nextNat32(true)!;
                        let byte3 = nextNat32(true)!;
                        let byte4 = nextNat32(true)!;
                        ((byte1 & 0x07) << 18) & (byte2 << 12) & (byte3 << 6) & byte4;
                    } else {
                        // Invalid first byte
                        return null;
                    };
                    return ?Char.fromNat32(nat32);
                };
            };
        };
    };
};