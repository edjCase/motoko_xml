import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";

module Utf8 {
    public class Reader(bytes : Blob) {
        let value : ?Text = Text.decodeUtf8(bytes); // TODO can this be chunked out/enumerable?
        let iter : Iter.Iter<Char> = switch (value) {
            case (null) { { next = func() { null } } };
            case (?v) Text.toIter(v);
        };
        var peekCache : ?Char = null;
        var currentValue : ?Char = null;

        public func current() : ?Char {
            currentValue;
        };

        public func peek() : ?Char {
            if (peekCache == null) {
                peekCache := iter.next();
            };
            return peekCache;
        };

        public func next() : ?Char {
            if (peekCache == null) {
                iter.next();
            } else {
                let next = peekCache;
                // clear cache since it moved to next
                peekCache := null;
                currentValue := next;
                next;
            };
        };

        public func skipWhitespace() : () {
            loop {
                switch (isNextWhitespace()) {
                    case (?true) {
                        let _ = next(); // Skip whitespace
                    };
                    case (_) {
                        return;
                    };
                };
            };
        };

        public func readUntilWhitespace() : ?Text {
            let charBuffer = Buffer.Buffer<Char>(1);
            loop {
                switch (isNextWhitespace()) {
                    case (?false) {
                        let _ = next(); // Skip whitespace
                    };
                    case (_) {
                        if (charBuffer.size() > 0) {
                            return ?Buffer.toText<Char>(charBuffer, Text.fromChar); // TODO optimize?
                        };
                        // continue until any characters have been gotten
                        let _ = next();
                    };
                };
            };
        };

        private func isNextWhitespace() : ?Bool {
            do ? {
                let nextChar = peek()!;
                isWhitespace(nextChar);
            };
        };

    };

    private func isWhitespace(c : Char) : Bool {
        switch (c) {
            case (' ') true;
            case ('\t') true;
            case ('\n') true;
            case ('\r') true;
            case (_) false;
        };
    };
};
