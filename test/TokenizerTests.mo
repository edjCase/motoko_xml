import Debug "mo:base/Debug";
import Tokenizer "../src/Tokenizer";
import Iter "mo:base/Iter";
import TestData "./TestData";

module {
    public func run() {
        successCases();
        failureCases();
    };

    private func successCases() {
        for (example in Iter.fromArray(TestData.examples)) {
            let tokens = Tokenizer.tokenizeText(example.raw);

            switch (tokens) {
                case (null) Debug.trap("Failed to tokenize");
                case (?t) {
                    var i = 0;
                    for (token in Iter.fromArray(t)) {
                        let expectedToken = example.tokens[i];
                        if (token != expectedToken) {
                            Debug.trap("Token mismatch. Expected:\n" # debug_show (expectedToken) # "\n\nActual:\n" # debug_show (token));
                        };
                        i += 1;
                    };
                };
            };
        };
    };

    private func failureCases() {
        for (example in Iter.fromArray(TestData.TokenizingFailureExamples)) {
            let tokens = Tokenizer.tokenizeText(example.rawXml);

            switch (tokens) {
                case (?t) Debug.trap("Expected failure but was sucessful.\n\nReason: " #example.reason # "\n\nRaw:\n" # example.rawXml # "\n\nTokens:\n" # debug_show (t));
                case (null) {
                    // Expected to fail
                };
            };
        };
    };
};
