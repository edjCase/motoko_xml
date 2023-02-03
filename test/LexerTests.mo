import Debug "mo:base/Debug";
import Lexer "../src/Lexer";
import Iter "mo:base/Iter";
import TestData "./TestData";

module {
    public func run() {

        let tokens = Lexer.tokenizeText(TestData.ex1_raw);

        switch (tokens) {
            case (null) Debug.trap("Failed to tokenize");
            case (?t) {
                var i = 0;
                for (token in Iter.fromArray(t)) {
                    let expectedToken = TestData.ex1_tokens[i];
                    if (token != expectedToken) {
                        Debug.trap("Token mismatch. Expected:\n" # debug_show (expectedToken) # "\n\nActual:\n" # debug_show (token));
                    };
                    i += 1;
                };
            };
        };
    };
};
