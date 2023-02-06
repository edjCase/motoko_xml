import Debug "mo:base/Debug";
import Parser "../src/Parser";
import TestData "TestData";
import Iter "mo:base/Iter";

module {
    public func run() {
        for (example in Iter.fromArray(TestData.examples)) {
            let doc = Parser.parseDocument(Iter.fromArray(example.tokens));

            if (doc != ?example.doc) {
                Debug.trap("Invalid document.\n\nExpected:\n" # debug_show (?example.doc) # "\n\nActual:\n" # debug_show (doc));
            };
        };
    };
};
