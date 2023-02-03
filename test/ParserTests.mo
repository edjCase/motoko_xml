import Debug "mo:base/Debug";
import Parser "../src/Parser";
import TestData "TestData";
import Iter "mo:base/Iter";

module {
    public func run() {
        let doc = Parser.parseDocument(Iter.fromArray(TestData.ex1_tokens));

        if (doc != ?TestData.ex1_doc) {
            Debug.trap("Invalid document.\n\nExpected:\n" # debug_show (TestData.ex1_doc) # "\n\nActual:\n" # debug_show (doc));
        };
    };
};
