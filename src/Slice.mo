import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
module Slice {

    public type Sequence<T> = {
        #array : [T];
        #buffer : Buffer.Buffer<T>;
        #slice : Slice<T>;
    };

    // TODO try to switch to a non allocating slice
    public class Slice<T>(
        sequence : Sequence<T>,
        comparer : (T, T) -> Bool,
        sliceOffset : Nat,
        sliceLength : ?Nat,
    ) : Slice<T> = sliceRef {

        private func getSequenceSize(sequence : Sequence<T>) : Nat {
            switch (sequence) {
                case (#array(a)) a.size();
                case (#buffer(b)) b.size();
                case (#slice(s)) s.size();
            };
        };
        let sequenceSize : Nat = getSequenceSize(sequence);
        let calculatedSliceLength : Nat = switch (sliceLength) {
            // If no sliceLength specified, stop at end of chars
            case (null) {
                if (sliceOffset >= sequenceSize) {
                    Debug.trap("Start index must be less than the sliceLength of the sequence");
                };
                sequenceSize - sliceOffset;
            };
            case (?l) {
                if (sliceOffset + l > sequenceSize) {
                    // print all the variables
                    Debug.trap("Start index + sliceLength must be less than the sliceLength of the sequence");
                };
                l;
            };
        };

        public func slice(offset : Nat, length : ?Nat) : Slice<T> {
            let newOffset = sliceOffset + offset;
            let newLength : Nat = switch (length) {
                case (null) {
                    // If not specified calculate the new length based off where the old legnth
                    calculatedSliceLength - offset;
                };
                case (?l) l;
            };
            Slice<T>(sequence, comparer, newOffset, ?newLength);
        };

        public func get(index : Nat) : T {
            getFromSequence(sequence, sliceOffset + index);
        };

        public func size() : Nat {
            calculatedSliceLength;
        };

        public func indexOfSequence(subset : Sequence<T>) : ?Nat {
            indexOfInternal(subset, false);
        };

        public func indexOf(item : T) : ?Nat {
            switch (sequence) {
                case (#array(a)) {
                    // iterate through the array and find the first index
                    label f for (i in Iter.range(0, a.size() - 1)) {
                        if (comparer(a[i], item)) {
                            return ?i;
                        };
                    };
                    null;
                };
                case (#buffer(b)) Buffer.indexOf(item, b, comparer);
                case (#slice(s)) s.indexOf(item);
            };
        };

        public func trimSingle(value : T) : Slice<T> {
            var start : Nat = 0;
            var end : Nat = size() - 1;
            if (comparer(get(start), value)) {
                start += 1;
            };
            if (comparer(get(end), value)) {
                end -= 1;
            };
            slice(start, ?(end + 1 - start));
        };

        private func indexOfInternal(subset : Sequence<T>, onlyStartsWith : Bool) : ?Nat {
            let subsetSize = getSequenceSize(subset);
            if (subsetSize > calculatedSliceLength) {
                return null;
            };
            // Create a loop that iterates through the slice, excluding the last x characters where x is the sequence size
            label f1 for (sliceIndex in Iter.range(0, calculatedSliceLength - subsetSize)) {
                // Check if the slice at the current index matches the sequence
                label f2 for (subsetIndex in Iter.range(0, subsetSize - 1)) {
                    let subsetValue = getFromSequence(subset, subsetIndex);
                    let sliceValue = get(sliceIndex + subsetIndex);
                    if (not comparer(sliceValue, subsetValue)) {
                        if (onlyStartsWith) {
                            // If only startswith, then fail on the first check
                            return null;
                        };
                        // If not matched, continue to next index
                        continue f1;
                    };
                };
                // If fully matched, return the index
                return ?sliceIndex;
            };
            return null;
        };

        public func toIter() : Iter.Iter<T> {
            switch (sequence) {
                case (#array(a)) toIterInternal(a.size(), func(i) = a[i]);
                case (#buffer(b)) toIterInternal(b.size(), func(i) = b.get(i));
                case (#slice(s)) s.toIter();
            };
        };

        private func getFromSequence(sequence : Sequence<T>, index : Nat) : T {
            switch (sequence) {
                case (#array(a)) a[index];
                case (#buffer(b)) b.get(index);
                case (#slice(s)) s.get(index);
            };
        };

        private func toIterInternal(size : Nat, getValue : Nat -> T) : Iter.Iter<T> {
            var iterLength = 0;
            // Create a new iter object to iterate through the slice
            {
                next = func() : ?T {

                    switch (sliceLength) {
                        case (null) {
                            if (iterLength + sliceOffset >= size) {
                                // If reached the end of array, return null
                                return null;
                            };
                        };
                        case (?l) {
                            if (iterLength >= l) {
                                // If reached the end of sliceLength, return null
                                return null;
                            };
                        };
                    };
                    let value = getValue(iterLength + sliceOffset);
                    iterLength += 1;
                    ?value;
                };
            };
        };

    };
};
