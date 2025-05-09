import Debug "mo:base/Debug";
import Tokenizer "../src/Tokenizer";
import Iter "mo:base/Iter";
import TestData "./TestData";
import { test } "mo:test";

// Tokenizer successful tests
for (example in Iter.fromArray(TestData.examples)) {

    test(
        "Tokenizer should succeed: " # example.name,
        func() {
            switch (Tokenizer.tokenize(example.raw.chars())) {
                case (#err(e)) Debug.trap("Failed to tokenize xml.\n\nError:\n" # debug_show (e) # "\n\nXml:\n" # debug_show (example.raw));
                case (#ok(tokens)) {
                    var i = 0;
                    for (token in Iter.fromArray(tokens)) {
                        let expectedToken = example.tokens[i];
                        if (token != expectedToken) {
                            Debug.trap("Token mismatch.\n\nExpected:\n" # debug_show (expectedToken) # "\n\nActual:\n" # debug_show (token));
                        };
                        i += 1;
                    };
                };
            };
        },
    );
};

// Tokenizer failure tests
for (example in Iter.fromArray(TestData.TokenizingFailureExamples)) {

    test(
        "Tokenizer should fail: " # example.name,
        func() {
            switch (Tokenizer.tokenize(example.rawXml.chars())) {
                case (#ok(tokens)) Debug.trap("Expected failure but was sucessful.\n\nExpected Error: " # debug_show (example.error) # "\n\nRaw:\n" # example.rawXml # "\n\nTokens:\n" # debug_show (tokens));
                case (#err(e)) {
                    if (e != example.error) {
                        Debug.trap("Wrong error.\n\nExpected Error:\n" # debug_show (example.error) # "\n\nActual Error:\n" # debug_show (e));
                    };
                    // If error matches, passed
                };
            };
        },
    );
};
