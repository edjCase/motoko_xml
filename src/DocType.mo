// module {

//     public type DocType = {
//         externalSubset : ExternalId;
//         internalSubset : [InternalSubset];
//     };

//     public type InternalSubset = {
//         #markup : {
//             #element : ElementDeclaration;
//             #attributeList : AttributeListDeclaration;
//             #entity : EntityDeclaration;
//             #notation : NotationDeclaration;
//             #processingInstruction : ProcessingInstruction;
//             #comment : Text;
//         };
//         #parsedEntity : Text;
//     };

//     public type EntityDeclaration = {
//         // &{name}
//         #general : Text;
//         // &%{name};
//         #parameter : Text;
//         // &#[0-9]+; or &#x[0-9a-fA-F]+;
//         #character : {
//             value : Nat;
//             type_ : { #decimal; #hexidecimal };
//         };
//     };

//     public type AttributeListDeclaration = {
//         name : Text;
//         s : [{
//             name : Text;
//             type_ : Any;

//         }];
//     };

//     public type ExternalEntity = {
//         name : Text;
//         id : ExternalId;
//     };

//     public type ExternalId = {
//         #system_ : Text;
//         #public_ : {
//             publicId : Text;
//             systemId : Text;
//         };
//     };

//     public type ElementDeclaration = {
//         name : Text;
//         contentSpec : {
//             #empty;
//             #any;
//             #mixed : [Text];
//             #children : [ElementChildConstraint];
//         };
//     };

//     public type ElementChildConstraint = {
//         content : {
//             #choice : [ContentParticle];
//             #sequence : [ContentParticle];
//         };
//         occurrance : OccuranceConstraint;
//     };

//     public type ContentParticle = {
//         content : {
//             #name : Text;
//             #choice : [ContentParticle];
//             #sequence : [ContentParticle];
//         };
//         occurance : OccuranceConstraint;
//     };

//     public type OccuranceConstraint = {
//         #once;
//         #zeroOrOnce;
//         #zeroOrMore;
//         #onceOrMore;
//     };
// };
