import ParserTests "./ParserTests";
import TokenizerTests "./TokenizerTests";
import Debug "mo:base/Debug";

ParserTests.run();
TokenizerTests.run();

Debug.print("Test run complete!");
