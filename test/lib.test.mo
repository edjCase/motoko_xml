import Iter "mo:core/Iter";
import TestData "./TestData";
import { test } "mo:test";
import Xml "../src";
import Text "mo:core/Text";
import Runtime "mo:core/Runtime";

// Xml successful tests
for (example in Iter.fromArray(TestData.examples)) {
  test(
    "Xml root element processing should succeed: " # example.name,
    func() {
      switch (Xml.fromBytes(Text.encodeUtf8(example.raw).vals())) {
        case (#err(e)) Runtime.trap("Failed to tokenize xml.\n\nError:\n" # debug_show (e) # "\n\nXml:\n" # debug_show (example.raw));
        case (#ok(root)) {
          if (root != example.processedElement) {

            Runtime.trap("Failed to parse xml.\n\nExpected:\n" # debug_show (example.processedElement) # "\n\nActual:\n" # debug_show (root) # "\n\nXml:\n" # debug_show (example.raw));
          };
        };
      };
    },
  );
};
