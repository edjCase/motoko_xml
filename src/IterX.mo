import Iter "mo:base/Iter";

module {

    public class IterReader<T>(iter : Iter.Iter<T>) {
        var peekCache : ?T = null;
        var currentValue : ?T = null;
        public var position : ?Nat = null;

        public func current() : ?T {
            currentValue;
        };

        public func peek() : ?T {
            switch (peekCache) {
                // If null then we need to get the next value
                // and store it, but not affect the current value
                case (null) peekCache := iter.next();
                case (_) ();
            };
            return peekCache;
        };

        public func next() : ?T {
            let next : ?T = switch (peekCache) {
                case (null) iter.next(); // If not peeked, then get the next value
                case (?peek) {
                    // If peeked, then use the peek value
                    // and dont iterate again
                    peekCache := null;
                    ?peek;
                };
            };
            switch (next) {
                case (null) null;
                case (?next) {
                    position := switch (position) {
                        case (null) ?0; // If null, then we are at the start
                        case (?p) ?(p + 1); // Otherwise increment
                    };
                    currentValue := ?next;
                    ?next;
                };
            };

        };
    };
};
