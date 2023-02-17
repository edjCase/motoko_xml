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
            switch (Parser.parseDocument(Iter.fromArray(example.tokens))) {
                case (#error(e)) {
                    Debug.trap("Error:\n\n" # debug_show (e));
                };
                case (#ok(d)) {
                    if (d != example.doc) {
                        Debug.trap("Invalid document.\n\nExpected:\n" # debug_show (example.doc) # "\n\nActual:\n" # debug_show (d) # "\n\nTokens: " # debug_show (example.tokens));
                    };
                };
            };
        };
    };

    private func failureCases() {
        for (example in Iter.fromArray(TestData.parsingFailureExamples)) {

            switch (Parser.parseDocument(Iter.fromArray(example.tokens))) {
                case (#error(e)) {
                    if (e != example.error) {
                        Debug.trap("Wrong error.\n\nExpected Error:\n" # debug_show (example.error) # "\n\nActual Error:\n" # debug_show (e));
                    };
                    // If matches, passed
                };
                case (#ok(d)) {
                    Debug.trap("Expected failure but was sucessful.\n\nExpected Error: " # debug_show (example.error) # "\n\nTokens:\n" # debug_show (example.tokens) # "\n\nDoc:\n" # debug_show (d));
                };
            };
        };
    };
};
