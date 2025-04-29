import Debug "mo:base/Debug";
import Parser "../src/Parser";
import TestData "TestData";
import Iter "mo:base/Iter";
import { test } "mo:test";

// Parser successful tests
for (example in Iter.fromArray(TestData.examples)) {
    test(
        "Parser should succeed: " # debug_show (example.name),
        func() {
            switch (Parser.parseDocument(Iter.fromArray(example.tokens))) {
                case (#err(e)) {
                    Debug.trap("Failed to parse xml.\n\nError:\n" # debug_show (e) # "\n\nTokens:\n" # debug_show (example.tokens));
                };
                case (#ok(d)) {
                    if (d != example.doc) {
                        Debug.trap("Invalid document.\n\nExpected:\n" # debug_show (example.doc) # "\n\nActual:\n" # debug_show (d) # "\n\nTokens:\n" # debug_show (example.tokens));
                    };
                };
            };
        },
    );
};

// Parser failure tests
for (example in Iter.fromArray(TestData.parsingFailureExamples)) {
    test(
        "Parser should fail: " # debug_show (example.name),
        func() {
            switch (Parser.parseDocument(Iter.fromArray(example.tokens))) {
                case (#err(e)) {
                    if (e != example.error) {
                        Debug.trap("Wrong error.\n\nExpected Error:\n" # debug_show (example.error) # "\n\nActual Error:\n" # debug_show (e));
                    };
                    // If matches, passed
                };
                case (#ok(d)) {
                    Debug.trap("Expected failure but was sucessful.\n\nExpected Error: " # debug_show (example.error) # "\n\nTokens:\n" # debug_show (example.tokens) # "\n\nDoc:\n" # debug_show (d));
                };
            };
        },
    );
};
