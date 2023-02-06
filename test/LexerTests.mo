import Debug "mo:base/Debug";
import Lexer "../src/Lexer";
import Iter "mo:base/Iter";
import TestData "./TestData";

module {
    public func run() {
        for (example in Iter.fromArray(TestData.examples)) {
            let tokens = Lexer.tokenizeText(example.raw);

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
};
