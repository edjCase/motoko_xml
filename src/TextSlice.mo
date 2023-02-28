import Slice "Slice";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
module {

    public type Sequence = Slice.Sequence<Char> or {
        #text : Text;
    };

    public class TextSlice(innerSlice : Slice.Slice<Char>) = sliceRef {

        public func slice(startIndex : Nat, length : ?Nat) : TextSlice {
            TextSlice(innerSlice.slice(startIndex, length));
        };

        public func asCharSequence() : Slice.Slice<Char> {
            innerSlice;
        };

        public func toIter() : Iter.Iter<Char> {
            innerSlice.toIter();
        };

        public func toText() : Text {
            Text.fromIter(toIter());
        };

        public func size() : Nat {
            innerSlice.size();
        };

        public func get(index : Nat) : Char {
            innerSlice.get(index);
        };

        public func indexOf(value : Char) : ?Nat {
            innerSlice.indexOf(value);
        };

        public func indexOfSequence(subset : Sequence) : ?Nat {
            let innerSubset : Slice.Sequence<Char> = mapSequence(subset);
            innerSlice.indexOfSequence(innerSubset);
        };

        public func trimSingle(value : Char) : TextSlice {
            TextSlice(innerSlice.trimSingle(value));
        };

        public func trimWhitespace() : TextSlice {
            var start : Nat = 0;
            var end : Nat = size() - 1;
            while (Char.isWhitespace(innerSlice.get(start))) {
                start += 1;
            };
            while (Char.isWhitespace(innerSlice.get(end))) {
                end -= 1;
            };
            slice(start, ?(end - start + 1));
        };

        public func split(separator : Char) : Iter.Iter<TextSlice> {
            let iter = toIter();
            var start : Nat = 0;
            var index : Nat = 0;
            let buffer = Buffer.Buffer<TextSlice>(5);
            label l loop {
                let c = switch (iter.next()) {
                    case null break l;
                    case (?c) c;
                };
                if (c == separator) {
                    buffer.add(slice(start, ?(index - start)));
                    start := index + 1;
                };
                index += 1;
            };
            buffer.add(slice(start, ?(index - start)));
            buffer.vals();
        };
    };

    public func slice(value : Sequence, startIndex : Nat, length : ?Nat) : TextSlice {
        let innerValue : Slice.Sequence<Char> = mapSequence(value);

        let innerSlice = Slice.Slice<Char>(innerValue, Char.equal, startIndex, length);
        TextSlice(innerSlice);
    };

    public func fromText(value : Text) : TextSlice {
        slice(#text(value), 0, null);
    };

    private func mapSequence(value : Sequence) : Slice.Sequence<Char> {
        switch (value) {
            case (#text(t)) #buffer(Buffer.fromIter<Char>(t.chars()));
            case (#array(a)) #array(a);
            case (#buffer(b)) #buffer(b);
            case (#slice(s)) #slice(s);
        };
    };
};
