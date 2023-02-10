import Debug "mo:base/Debug";
import Parser "../src/Parser";
import TestData "TestData";
import Iter "mo:base/Iter";

module {
    public func run() {
        successCases();
        failureCases();
    };

    private func successCases() {
        for (example in Iter.fromArray(TestData.examples)) {
            let doc = Parser.parseDocument(Iter.fromArray(example.tokens));

            if (doc != ?example.doc) {
                Debug.trap("Invalid document.\n\nExpected:\n" # debug_show (?example.doc) # "\n\nActual:\n" # debug_show (doc));
            };
        };
    };

    private func failureCases() {
        for (example in Iter.fromArray(TestData.parsingFailureExamples)) {
            let doc = Parser.parseDocument(Iter.fromArray(example.tokens));

            switch (doc) {
                case (?d) Debug.trap("Expected failure but was sucessful.\n\nReason: " #example.reason # "\n\nTokens:\n" # debug_show (example.tokens) # "\n\nDoc:\n" # debug_show (d));
                case (null) {
                    // Expected to fail
                };
            };
        };
    };
};
