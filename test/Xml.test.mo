import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import TestData "./TestData";
import { test } "mo:test";
import Xml "../src/Xml";
import Text "mo:base/Text";
import Blob "mo:base/Blob";
import TextX "mo:xtended-text/TextX";

// Xml successful tests
for (example in Iter.fromArray(TestData.examples)) {
    test(
        "Xml root element processing should succeed: " # example.name,
        func() {
            switch (Xml.deserializeFromBytes(TextX.toUtf8Bytes(example.raw.chars()))) {
                case (#error(e)) Debug.trap("Failed to tokenize xml.\n\nError:\n" # debug_show (e) # "\n\nXml:\n" # debug_show (example.raw));
                case (#ok(root)) {
                    if (root != example.processedElement) {

                        Debug.trap("Failed to parse xml.\n\nExpected:\n" # debug_show (example.processedElement) # "\n\nActual:\n" # debug_show (root) # "\n\nXml:\n" # debug_show (example.raw));
                    };
                };
            };
        },
    );
};
