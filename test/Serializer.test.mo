import Iter "mo:core/Iter";
import TestData "./TestData";
import { test } "mo:test";
import Xml "../src";
import Text "mo:core/Text";
import Runtime "mo:core/Runtime";

for (example in Iter.fromArray(TestData.serializerExamples)) {

  test(
    "Encoder: " # example.name,
    func() {
      let chars = Xml.toText(example.element);
      let actual = Text.fromIter(chars);
      if (actual != example.expected) {
        Runtime.trap("Failed to encode xml.\n\nExpected:\n" # debug_show (example.expected) # "\n\nActual:\n" # debug_show (actual) # "\n\nElement:\n" # debug_show (example.element));
      };
    },
  );
};
