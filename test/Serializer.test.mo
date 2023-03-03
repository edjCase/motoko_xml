import Debug "mo:base/Debug";
import Tokenizer "../src/Tokenizer";
import Iter "mo:base/Iter";
import TestData "./TestData";
import { test } "mo:test";
import Serializer "../src/Serializer";
import Xml "../src/Xml";
import Text "mo:base/Text";

for (example in Iter.fromArray(TestData.serializerExamples)) {

    test(
        "Encoder: " # example.name,
        func() {
            let chars = Xml.serialize(example.element);
            let actual = Text.fromIter(chars);
            if (actual != example.expected) {
                Debug.trap("Failed to encode xml.\n\nExpected:\n" # debug_show (example.expected) # "\n\nActual:\n" # debug_show (actual) # "\n\nElement:\n" # debug_show (example.element));
            };
        },
    );
};
