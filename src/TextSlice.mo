import Slice "Slice";
import Iter "mo:core@1/Iter";
import Text "mo:core@1/Text";
import Char "mo:core@1/Char";
import List "mo:core@1/List";

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
      let buffer = List.empty<TextSlice>();
      label l loop {
        let c = switch (iter.next()) {
          case null break l;
          case (?c) c;
        };
        if (c == separator) {
          List.add(buffer, slice(start, ?(index - start)));
          start := index + 1;
        };
        index += 1;
      };
      List.add(buffer, slice(start, ?(index - start)));
      List.values(buffer);
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
      case (#text(t)) #list(List.fromIter<Char>(t.chars()));
      case (#array(a)) #array(a);
      case (#list(l)) #list(l);
      case (#slice(s)) #slice(s);
    };
  };
};
