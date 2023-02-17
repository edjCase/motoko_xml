// private func validateNameValue(name : Text) : { #ok; #error : {} } {
//     let iter = name.chars();
//     // Check first character
//     switch (iter.next()) {
//         case (null) return #error({});
//         case (?c) {
//             // Validate first characters don't include digits, diacritics, the full stop and the hyphen.
//             if (isInvalidNameChar(c, true)) {
//                 return #error({});
//             };
//         };
//     };
//     // Check other characters
//     for (c in iter) {
//         if (isInvalidNameChar(c, false)) {
//             return #error({});
//         };
//     };
//     #ok;
// };

// private func isInvalidNameChar(c : Char, isFirstChar : Bool) : Bool {
//     // NameStartChar:   ":" | [A-Z] | "_" | [a-z] | [#xC0-#xD6] | [#xD8-#xF6] | [#xF8-#x2FF]
//     //                  | [#x370-#x37D] | [#x37F-#x1FFF] | [#x200C-#x200D] | [#x2070-#x218F]
//     //                  | [#x2C00-#x2FEF] | [#x3001-#xD7FF] | [#xF900-#xFDCF] | [#xFDF0-#xFFFD]
//     //                  | [#x10000-#xEFFFF]
//     // NameChar: NameStartChar | "-" | "." | [0-9] | #xB7 | [#x0300-#x036F] | [#x203F-#x2040]
//     switch (c) {
//         case '-' not isFirstChar;
//         case '_' not isFirstChar;
//         case ':' not isFirstChar;
//         case _ {
//             // A-Za-z
//             if (Char.isAlphabetic(c)) {
//                 return true;
//             };
//             // 0-9 (except first char)
//             if (Char.isDigit(c)) {
//                 return not isFirstChar;
//             };
//             let unicodeValue = Char.toNat32(c);

//             // All allowed unicode chars
//             let bounds : [(Nat32, Nat32)] = [
//                 (0xC0, 0xD6),
//                 (0xD8, 0xF6),
//                 (0xF8, 0x2FF),
//                 (0x370, 0x37D),
//                 (0x37F, 0x1FFF),
//                 (0x200C, 0x200D),
//                 (0x2070, 0x218F),
//                 (0x2C00, 0x2FEF),
//                 (0x3001, 0xD7FF),
//                 (0xF900, 0xFDCF),
//                 (0xFDF0, 0xFFFD),
//                 (0x10000, 0xEFFFF),
//             ];
//             if (betweenBounds(unicodeValue, bounds)) {
//                 return true;
//             };
//             if (not isFirstChar) {
//                 // Unicode allowed in all but first character
//                 let bounds : [(Nat32, Nat32)] = [
//                     (0xB7, 0xB7),
//                     (0x300, 0x36F),
//                     (0x203F, 0x2040),
//                 ];
//                 if (betweenBounds(unicodeValue, bounds)) {
//                     return true;
//                 };
//             };
//             return false;
//         };
//     };
// };

// private func betweenBounds(value : Nat32, bounds : [(Nat32, Nat32)]) : Bool {
//     Array.foldRight(
//         bounds,
//         true,
//         func(bound : (Nat32, Nat32), isBetween : Bool) : Bool {
//             isBetween and value >= bound.0 and value <= bound.1
//         },
//     );
// };
