import Parser "../src/Parser";
import Token "../src/Token";
import Document "../src/Document";
import Element "../src/Element";

module {

    public type EncoderExample = {
        name : Text;
        element : Element.Element;
        expected : Text;
    };

    public let serializerExamples : [EncoderExample] = [
        {
            name = "Empty element";
            element = {
                attributes = [];
                children = #open([]);
                name = "root";
            };
            expected = "<root></root>";
        },
        {
            name = "Self closing element";
            element = {
                attributes = [];
                children = #selfClosing();
                name = "root";
            };
            expected = "<root/>";
        },
        {
            name = "Element with text";
            element = {
                attributes = [];
                children = #open([
                    #text("Test")
                ]);
                name = "root";
            };
            expected = "<root>Test</root>";
        },
        {
            name = "Element with special text";
            element = {
                attributes = [];
                children = #open([
                    #text("Test & < > ' \"")
                ]);
                name = "root";
            };
            expected = "<root>Test &amp; &lt; &gt; &apos; &quot;</root>";
        },
        {
            name = "Nested elements";
            element = {
                attributes = [];
                children = #open([
                    #element({
                        attributes = [];
                        children = #open([
                            #element({
                                attributes = [];
                                children = #selfClosing;
                                name = "bottom";
                            })
                        ]);
                        name = "mid";
                    })
                ]);
                name = "top";
            };
            expected = "<top><mid><bottom/></mid></top>";
        },
        {
            name = "Element with attributes";
            element = {
                attributes = [
                    {
                        name = "a";
                        value = ?"b";
                    },
                    {
                        name = "c";
                        value = ?"1";
                    },
                    {
                        name = "d";
                        value = null;
                    },
                ];
                children = #open([
                    #element({
                        attributes = [
                            {
                                name = "aZ";
                                value = ?"zA";
                            },
                        ];
                        children = #selfClosing;
                        name = "inner";
                    })
                ]);
                name = "root";
            };
            expected = "<root a=\"b\" c=\"1\" d=\"\"><inner aZ=\"zA\"/></root>";
        },
        {
            name = "Element with special character attributes";
            element = {
                attributes = [{
                    name = "a";
                    value = ?"Test & < > ' \"";
                }];
                children = #selfClosing;
                name = "root";
            };
            expected = "<root a=\"Test &amp; &lt; &gt; &apos; &quot;\"/>";
        },
    ];

    public type Example = {
        name : Text;
        raw : Text;
        tokens : [Token.Token];
        doc : Document.Document;
        processedElement : Element.Element;
    };
    public let examples : [Example] = [
        {
            name = "Empty document";
            raw = "<root></root>";
            tokens = [
                #startTag({
                    attributes = [];
                    name = "root";
                    selfClosing = false;
                }),
                #endTag({ name = "root" }),
            ];
            doc = {
                encoding = null;
                processInstructions = [];
                root = {
                    attributes = [];
                    children = #open([]);
                    name = "root";
                };
                standalone = null;
                version = null;
                docType = null;
            };
            processedElement = {
                attributes = [];
                children = #open([]);
                name = "root";
            };
        },
        {
            name = "Escaped characters";
            raw = "<root>&lt;&gt;&amp;&apos;&quot;&#123;&#x1F923;</root>";
            tokens = [
                #startTag({
                    attributes = [];
                    name = "root";
                    selfClosing = false;
                }),
                #text("&lt;&gt;&amp;&apos;&quot;&#123;&#x1F923;"),
                #endTag({ name = "root" }),
            ];
            doc = {
                encoding = null;
                processInstructions = [];
                root = {
                    attributes = [];
                    children = #open([#text("&lt;&gt;&amp;&apos;&quot;&#123;&#x1F923;")]);
                    name = "root";
                };
                standalone = null;
                version = null;
                docType = null;
            };
            processedElement = {
                attributes = [];
                children = #open([
                    #text("<>&'\"{🤣")
                ]);
                name = "root";
            };
        },
        {
            name = "CDATA Tag";
            raw = "<root><![CDATA[You will see this in the document and can use reserved characters like < > & \"]]></root>";
            tokens = [
                #startTag({
                    attributes = [];
                    name = "root";
                    selfClosing = false;
                }),
                #cdata("You will see this in the document and can use reserved characters like < > & \""),
                #endTag({ name = "root" }),
            ];
            doc = {
                encoding = null;
                processInstructions = [];
                root = {
                    attributes = [];
                    children = #open([#cdata("You will see this in the document and can use reserved characters like < > & \"")]);
                    name = "root";
                };
                standalone = null;
                version = null;
                docType = null;
            };
            processedElement = {
                attributes = [];
                children = #open([
                    #text("You will see this in the document and can use reserved characters like < > & \"")
                ]);
                name = "root";
            };
        },
        {
            name = "Comment Tag";
            raw = "<root><!--You will see this in the document and can use reserved characters like < > & \"--></root>";
            tokens = [
                #startTag({
                    attributes = [];
                    name = "root";
                    selfClosing = false;
                }),
                #comment("You will see this in the document and can use reserved characters like < > & \""),
                #endTag({ name = "root" }),
            ];
            doc = {
                encoding = null;
                processInstructions = [];
                root = {
                    attributes = [];
                    children = #open([#comment("You will see this in the document and can use reserved characters like < > & \"")]);
                    name = "root";
                };
                standalone = null;
                version = null;
                docType = null;
            };
            processedElement = {
                attributes = [];
                children = #open([]);
                name = "root";
            };
        },
        {
            name = "XML Declaration";
            raw = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><top a=b c=\"d\"><!-- comment --><mid t=5/><bottom >Content</ bottom></top>";
            tokens = [
                #xmlDeclaration({
                    encoding = ?"UTF-8";
                    version = { major = 1; minor = 0 };
                    standalone = null;
                }),
                #startTag({
                    attributes = [
                        {
                            name = "a";
                            value = ?"b";
                        },
                        { name = "c"; value = ?"d" },
                    ];
                    name = "top";
                    selfClosing = false;
                }),
                #comment(" comment "),
                #startTag({
                    attributes = [
                        {
                            name = "t";
                            value = ?"5";
                        },
                    ];
                    name = "mid";
                    selfClosing = true;
                }),
                #startTag({
                    attributes = [];
                    name = "bottom";
                    selfClosing = false;
                }),
                #text("Content"),
                #endTag({ name = "bottom" }),
                #endTag({ name = "top" }),
            ];
            doc = {
                encoding = ?"UTF-8";
                processInstructions = [];
                root = {
                    attributes = [{ name = "a"; value = ?"b" }, { name = "c"; value = ?"d" }];
                    children = #open([
                        #comment(" comment "),
                        #element({
                            attributes = [{ name = "t"; value = ?"5" }];
                            children = #selfClosing;
                            name = "mid";
                        }),
                        #element({
                            attributes = [];
                            children = #open([#text("Content")]);
                            name = "bottom";
                        }),
                    ]);
                    name = "top";
                };
                standalone = null;
                version = ?{ major = 1; minor = 0 };
                docType = null;
            };
            processedElement = {
                attributes = [{ name = "a"; value = ?"b" }, { name = "c"; value = ?"d" }];
                children = #open([
                    #element({
                        attributes = [{ name = "t"; value = ?"5" }];
                        children = #selfClosing;
                        name = "mid";
                    }),
                    #element({
                        attributes = [];
                        children = #open([#text("Content")]);
                        name = "bottom";
                    }),
                ]);
                name = "top";
            };
        },
        {
            name = "DOCTYPE ELEMENT";
            raw = "<!DOCTYPE root [ <!ELEMENT foo (#PCDATA)> <!ELEMENT img EMPTY> <!ELEMENT img2 ANY> <!ELEMENT img3 (foo)> <!ELEMENT img4 (foo|img)> <!ELEMENT img5 (foo,img)> <!ELEMENT img6 (foo*)> <!ELEMENT img7 (foo+)> <!ELEMENT img8 (foo?)> <!ELEMENT img9 ((foo|img)*)>]><root></root>";
            tokens = [
                #docType({
                    rootElementName = "root";
                    typeDefinition = {
                        externalTypes = null;
                        internalTypes = [
                            #element({
                                allowableContents = #children(
                                    #sequence([{
                                        kind = #element("#PCDATA");
                                        ocurrance = #one;
                                    }])
                                );
                                name = "foo";
                            }),
                            #element({
                                allowableContents = #empty;
                                name = "img";
                            }),
                            #element({
                                allowableContents = #any;
                                name = "img2";
                            }),
                            #element({
                                allowableContents = #children(
                                    #sequence([{
                                        kind = #element("foo");
                                        ocurrance = #one;
                                    }])
                                );
                                name = "img3";
                            }),
                            #element({
                                allowableContents = #children(
                                    #choice([
                                        {
                                            kind = #element("foo");
                                            ocurrance = #one;
                                        },
                                        {
                                            kind = #element("img");
                                            ocurrance = #one;
                                        },
                                    ])
                                );
                                name = "img4";
                            }),
                            #element({
                                allowableContents = #children(
                                    #sequence([
                                        {
                                            kind = #element("foo");
                                            ocurrance = #one;
                                        },
                                        {
                                            kind = #element("img");
                                            ocurrance = #one;
                                        },
                                    ])
                                );
                                name = "img5";
                            }),
                            #element({
                                allowableContents = #children(#sequence([{ kind = #element("foo"); ocurrance = #zeroOrMore }]));
                                name = "img6";
                            }),
                            #element({
                                allowableContents = #children(
                                    #sequence([{
                                        kind = #element("foo");
                                        ocurrance = #oneOrMore;
                                    }])
                                );
                                name = "img7";
                            }),
                            #element({
                                allowableContents = #children(
                                    #sequence([{
                                        kind = #element("foo");
                                        ocurrance = #zeroOrOne;
                                    }])
                                );
                                name = "img8";
                            }),
                            #element({
                                allowableContents = #children(
                                    #sequence([{
                                        kind = #choice([
                                            {
                                                kind = #element("foo");
                                                ocurrance = #one;
                                            },
                                            {
                                                kind = #element("img");
                                                ocurrance = #one;
                                            },
                                        ]);
                                        ocurrance = #zeroOrMore;
                                    }])
                                );
                                name = "img9";
                            }),
                        ];
                    };
                }),
                #startTag({
                    name = "root";
                    attributes = [];
                    selfClosing = false;
                }),
                #endTag({ name = "root" }),
            ];
            doc = {
                docType = ?{
                    rootElementName = "root";
                    typeDefinition = {
                        externalTypes = null;
                        internalTypes = [
                            #element({
                                allowableContents = #children(
                                    #sequence([{
                                        kind = #element("#PCDATA");
                                        ocurrance = #one;
                                    }])
                                );
                                name = "foo";
                            }),
                            #element({
                                allowableContents = #empty;
                                name = "img";
                            }),
                            #element({ allowableContents = #any; name = "img2" }),
                            #element({
                                allowableContents = #children(
                                    #sequence([{
                                        kind = #element("foo");
                                        ocurrance = #one;
                                    }])
                                );
                                name = "img3";
                            }),
                            #element({
                                allowableContents = #children(
                                    #choice([{ kind = #element("foo"); ocurrance = #one }, { kind = #element("img"); ocurrance = #one }])
                                );
                                name = "img4";
                            }),
                            #element({
                                allowableContents = #children(
                                    #sequence([
                                        {
                                            kind = #element("foo");
                                            ocurrance = #one;
                                        },
                                        {
                                            kind = #element("img");
                                            ocurrance = #one;
                                        },
                                    ])
                                );
                                name = "img5";
                            }),
                            #element({
                                allowableContents = #children(
                                    #sequence([{
                                        kind = #element("foo");
                                        ocurrance = #zeroOrMore;
                                    }])
                                );
                                name = "img6";
                            }),
                            #element({
                                allowableContents = #children(
                                    #sequence([{
                                        kind = #element("foo");
                                        ocurrance = #oneOrMore;
                                    }])
                                );
                                name = "img7";
                            }),
                            #element({
                                allowableContents = #children(
                                    #sequence([{
                                        kind = #element("foo");
                                        ocurrance = #zeroOrOne;
                                    }])
                                );
                                name = "img8";
                            }),
                            #element({
                                allowableContents = #children(
                                    #sequence([{
                                        kind = #choice([
                                            {
                                                kind = #element("foo");
                                                ocurrance = #one;
                                            },
                                            {
                                                kind = #element("img");
                                                ocurrance = #one;
                                            },
                                        ]);
                                        ocurrance = #zeroOrMore;
                                    }])
                                );
                                name = "img9";
                            }),
                        ];
                    };
                };
                encoding = null;
                processInstructions = [];
                root = { attributes = []; children = #open([]); name = "root" };
                standalone = null;
                version = null;
            };
            processedElement = {
                attributes = [];
                children = #open([]);
                name = "root";
            };
        },
        {
            name = "DOCTYPE ATTLIST";
            raw = "<!DOCTYPE root [ <!ATTLIST a1 n1 CDATA #REQUIRED> <!ATTLIST a2 n2 IDREF #IMPLIED> <!ATTLIST a3 n3 NMTOKEN #FIXED \"f\">  <!ATTLIST a4 n4 ID #REQUIRED> <!ATTLIST a5 n5 IDREFS #REQUIRED>  <!ATTLIST a6 n6 ENTITY #REQUIRED>   <!ATTLIST a7 n7 ENTITIES #REQUIRED> <!ATTLIST a8 n8 NMTOKENS #REQUIRED> <!ATTLIST a9 n9 NOTATION (nota|tion) #REQUIRED> <!ATTLIST a10 n10 (one|two) #REQUIRED>  ] ><root></root>";
            tokens = [
                #docType({
                    rootElementName = "root";
                    typeDefinition = {
                        externalTypes = null;
                        internalTypes = [
                            #attribute({
                                elementName = "a1";
                                name = "n1";
                                type_ = #cdata;
                                defaultValue = #required;
                            }),
                            #attribute({
                                elementName = "a2";
                                name = "n2";
                                type_ = #idRef;
                                defaultValue = #implied;
                            }),
                            #attribute({
                                elementName = "a3";
                                name = "n3";
                                type_ = #nmToken;
                                defaultValue = #fixed("f");
                            }),
                            #attribute({
                                elementName = "a4";
                                name = "n4";
                                type_ = #id;
                                defaultValue = #required;
                            }),
                            #attribute({
                                elementName = "a5";
                                name = "n5";
                                type_ = #idRefs;
                                defaultValue = #required;
                            }),
                            #attribute({
                                elementName = "a6";
                                name = "n6";
                                type_ = #entity;
                                defaultValue = #required;
                            }),
                            #attribute({
                                elementName = "a7";
                                name = "n7";
                                type_ = #entities;
                                defaultValue = #required;
                            }),
                            #attribute({
                                elementName = "a8";
                                name = "n8";
                                type_ = #nmTokens;
                                defaultValue = #required;
                            }),
                            #attribute({
                                elementName = "a9";
                                name = "n9";
                                type_ = #notation(["nota", "tion"]);
                                defaultValue = #required;
                            }),
                            #attribute({
                                elementName = "a10";
                                name = "n10";
                                type_ = #enumeration(["one", "two"]);
                                defaultValue = #required;
                            }),
                        ];
                    };
                }),
                #startTag({
                    name = "root";
                    attributes = [];
                    selfClosing = false;
                }),
                #endTag({ name = "root" }),
            ];
            doc = {
                docType = ?{
                    rootElementName = "root";
                    typeDefinition = {
                        externalTypes = null;
                        internalTypes = [
                            #attribute({
                                elementName = "a1";
                                name = "n1";
                                type_ = #cdata;
                                defaultValue = #required;
                            }),
                            #attribute({
                                elementName = "a2";
                                name = "n2";
                                type_ = #idRef;
                                defaultValue = #implied;
                            }),
                            #attribute({
                                elementName = "a3";
                                name = "n3";
                                type_ = #nmToken;
                                defaultValue = #fixed("f");
                            }),
                            #attribute({
                                elementName = "a4";
                                name = "n4";
                                type_ = #id;
                                defaultValue = #required;
                            }),
                            #attribute({
                                elementName = "a5";
                                name = "n5";
                                type_ = #idRefs;
                                defaultValue = #required;
                            }),
                            #attribute({
                                elementName = "a6";
                                name = "n6";
                                type_ = #entity;
                                defaultValue = #required;
                            }),
                            #attribute({
                                elementName = "a7";
                                name = "n7";
                                type_ = #entities;
                                defaultValue = #required;
                            }),
                            #attribute({
                                elementName = "a8";
                                name = "n8";
                                type_ = #nmTokens;
                                defaultValue = #required;
                            }),
                            #attribute({
                                elementName = "a9";
                                name = "n9";
                                type_ = #notation(["nota", "tion"]);
                                defaultValue = #required;
                            }),
                            #attribute({
                                elementName = "a10";
                                name = "n10";
                                type_ = #enumeration(["one", "two"]);
                                defaultValue = #required;
                            }),
                        ];
                    };
                };
                encoding = null;
                processInstructions = [];
                root = { attributes = []; children = #open([]); name = "root" };
                standalone = null;
                version = null;
            };
            processedElement = {
                attributes = [];
                children = #open([]);
                name = "root";
            };
        },
        {
            name = "DOCTYPE ENTITY";
            raw = "<!DOCTYPE root [ <!ENTITY n1 \"v1\"> <!ENTITY n2 SYSTEM \"Uri1\"> <!ENTITY n3 PUBLIC \"Id1\" \"Uri2\"> <!ENTITY n4 SYSTEM \"Uri3\" NDATA nd1> <!ENTITY n5 PUBLIC \"Id2\" \"Uri4\" NDATA nd2> <!ENTITY % n6 \"v2\"> <!ENTITY % n7 SYSTEM \"Uri5\"> <!ENTITY % n8 PUBLIC \"Id3\" \"Uri6\"> <!ENTITY n9 \"%n6\"> ]\n><root>&n1;&n2;&n3;&n4;&n5;&n9;</root>";
            tokens = [
                #docType({
                    rootElementName = "root";
                    typeDefinition = {
                        externalTypes = null;
                        internalTypes = [
                            #generalEntity({
                                name = "n1";
                                type_ = #internal("v1");
                            }),
                            #generalEntity({
                                name = "n2";
                                type_ = #external({
                                    url = "Uri1";
                                    notationId = null;
                                    type_ = #system_;
                                });
                            }),
                            #generalEntity({
                                name = "n3";
                                type_ = #external({
                                    url = "Uri2";
                                    notationId = null;
                                    type_ = #public_({ id = "Id1" });
                                });
                            }),
                            #generalEntity({
                                name = "n4";
                                type_ = #external({
                                    url = "Uri3";
                                    notationId = ?"nd1";
                                    type_ = #system_;
                                });
                            }),
                            #generalEntity({
                                name = "n5";
                                type_ = #external({
                                    url = "Uri4";
                                    notationId = ?"nd2";
                                    type_ = #public_({ id = "Id2" });
                                });
                            }),
                            #parameterEntity({
                                name = "n6";
                                type_ = #internal("v2");
                            }),
                            #parameterEntity({
                                name = "n7";
                                type_ = #external({
                                    url = "Uri5";
                                    type_ = #system_;
                                });
                            }),
                            #parameterEntity({
                                name = "n8";
                                type_ = #external({
                                    url = "Uri6";
                                    type_ = #public_({
                                        id = "Id3";
                                    });
                                });
                            }),
                            #generalEntity({
                                name = "n9";
                                type_ = #internal("%n6");
                            }),
                        ];
                    };
                }),
                #startTag({
                    name = "root";
                    attributes = [];
                    selfClosing = false;
                }),
                #text("&n1;&n2;&n3;&n4;&n5;&n9;"),
                #endTag({ name = "root" }),
            ];
            doc = {
                docType = ?{
                    rootElementName = "root";
                    typeDefinition = {
                        externalTypes = null;
                        internalTypes = [
                            #generalEntity({
                                name = "n1";
                                type_ = #internal("v1");
                            }),
                            #generalEntity({
                                name = "n2";
                                type_ = #external({
                                    url = "Uri1";
                                    notationId = null;
                                    type_ = #system_;
                                });
                            }),
                            #generalEntity({
                                name = "n3";
                                type_ = #external({
                                    url = "Uri2";
                                    notationId = null;
                                    type_ = #public_({ id = "Id1" });
                                });
                            }),
                            #generalEntity({
                                name = "n4";
                                type_ = #external({
                                    url = "Uri3";
                                    notationId = ?"nd1";
                                    type_ = #system_;
                                });
                            }),
                            #generalEntity({
                                name = "n5";
                                type_ = #external({
                                    url = "Uri4";
                                    notationId = ?"nd2";
                                    type_ = #public_({ id = "Id2" });
                                });
                            }),
                            #parameterEntity({
                                name = "n6";
                                type_ = #internal("v2");
                            }),
                            #parameterEntity({
                                name = "n7";
                                type_ = #external({
                                    url = "Uri5";
                                    type_ = #system_;
                                });
                            }),
                            #parameterEntity({
                                name = "n8";
                                type_ = #external({
                                    url = "Uri6";
                                    type_ = #public_({
                                        id = "Id3";
                                    });
                                });
                            }),
                            #generalEntity({
                                name = "n9";
                                type_ = #internal("%n6");
                            }),
                        ];
                    };
                };
                encoding = null;
                processInstructions = [];
                root = {
                    attributes = [];
                    children = #open([
                        #text("&n1;&n2;&n3;&n4;&n5;&n9;")
                    ]);
                    name = "root";
                };
                standalone = null;
                version = null;
            };
            processedElement = {
                attributes = [];
                children = #open([
                    #text("v1&n2;&n3;&n4;&n5;v2") // Dont support external entity replacement
                ]);
                name = "root";
            };
        },
        {
            name = "DOCTYPE NOTATION";
            raw = "<!DOCTYPE root [ <!NOTATION n1 SYSTEM \"Uri1\"> <!NOTATION n2 PUBLIC \"Id1\"> <!NOTATION n3 PUBLIC \"Id2\" \"Uri2\">  ]\n><root></root>";
            tokens = [
                #docType({
                    rootElementName = "root";
                    typeDefinition = {
                        externalTypes = null;
                        internalTypes = [
                            #notation({
                                name = "n1";
                                type_ = #system_({
                                    url = "Uri1";
                                });
                            }),
                            #notation({
                                name = "n2";
                                type_ = #public_({
                                    url = null;
                                    id = "Id1";
                                });
                            }),
                            #notation({
                                name = "n3";
                                type_ = #public_({
                                    url = ?"Uri2";
                                    id = "Id2";
                                });
                            }),
                        ];
                    };
                }),
                #startTag({
                    name = "root";
                    attributes = [];
                    selfClosing = false;
                }),
                #endTag({ name = "root" }),
            ];
            doc = {
                docType = ?{
                    rootElementName = "root";
                    typeDefinition = {
                        externalTypes = null;
                        internalTypes = [
                            #notation({
                                name = "n1";
                                type_ = #system_({
                                    url = "Uri1";
                                });
                            }),
                            #notation({
                                name = "n2";
                                type_ = #public_({
                                    url = null;
                                    id = "Id1";
                                });
                            }),
                            #notation({
                                name = "n3";
                                type_ = #public_({
                                    url = ?"Uri2";
                                    id = "Id2";
                                });
                            }),
                        ];
                    };
                };
                encoding = null;
                processInstructions = [];
                root = { attributes = []; children = #open([]); name = "root" };
                standalone = null;
                version = null;
            };
            processedElement = {
                attributes = [];
                children = #open([]);
                name = "root";
            };
        },
        {
            name = "DOCTYPE COMMENT";
            raw = "<!DOCTYPE root [ <!--Comment--> ]><root></root>";
            tokens = [
                #docType({
                    rootElementName = "root";
                    typeDefinition = {
                        externalTypes = null;
                        internalTypes = [
                            #comment("Comment"),
                        ];
                    };
                }),
                #startTag({
                    name = "root";
                    attributes = [];
                    selfClosing = false;
                }),
                #endTag({ name = "root" }),
            ];
            doc = {
                docType = ?{
                    rootElementName = "root";
                    typeDefinition = {
                        externalTypes = null;
                        internalTypes = [
                            #comment("Comment"),
                        ];
                    };
                };
                encoding = null;
                processInstructions = [];
                root = { attributes = []; children = #open([]); name = "root" };
                standalone = null;
                version = null;
            };
            processedElement = {
                attributes = [];
                children = #open([]);
                name = "root";
            };
        },
        {
            name = "RSS Feed";
            raw : Text = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><feed xmlns=\"http://www.w3.org/2005/Atom\" xml:lang=\"en\"><title>The Verge - All Posts</title><icon>https://cdn.vox-cdn.com/community_logos/52801/VER_Logomark_32x32..png</icon><updated>2022-11-21T21:30:42-05:00</updated><id>https://www.theverge.com/rss/full.xml</id><link type=\"text/html\" href=\"https://www.theverge.com/\" rel=\"alternate\"/><entry><published>2022-11-21T21:30:42-05:00</published><updated>2022-11-21T21:30:42-05:00</updated><title>Twitter is making DMs encrypted and adding video, voice chat, per Elon Musk</title><content type=\"html\"><figure><img alt=\"An illustration of the Twitter logo\" src=\"https://cdn.vox-cdn.com/thumbor/6kBqimyOvt-iCvNDVhv2okF4ey4=/0x0:3000x2000/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659917/acastro_STK050_04.0.jpg\" /><figcaption>Illustration by Alex Castro / The Verge</figcaption></figure><p id=\"TvAhZo\">Twitter’s new owner, Elon Musk, has been public about his desire to improve how the social network’s direct messages work. In a meeting with employees today, he spelled out exactly what that looks like.</p><p id=\"6MmlUD\">Framed by presentation slides titled “Twitter 2.0” at Twitter’s San Fransisco headquarters on Monday, Musk told employees that the company would encrypt DMs and work to add encrypted video and voice calling between accounts, according to a recording of the meeting obtained by<em>The Verge</em>.</p><p id=\"Z8NlgY\">“We want to enable users to be able to communicate without being concerned about their privacy, [or] without being concerned about a data breach at Twitter causing all of their DMs to hit the web, or think that maybe someone at Twitter could be spying on...</p><p><a href=\"https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling\">Continue reading&hellip;</a></p></content><link rel=\"alternate\" type=\"text/html\" href=\"https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling\"/><id>https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling</id><author><name>Alex Heath</name></author></entry><entry><published>2022-11-21T20:24:25-05:00</published><updated>2022-11-21T20:24:25-05:00</updated><title>Domino’s is building an all-electric pizza delivery fleet with Chevy Bolts</title><content type=\"html\"><figure><img alt=\"Two chevy bolt ev cars, wrapped in domino’s artwork are parked in front of a domino’s pizza store with one of the cars hooked up to a charger.\" src=\"https://cdn.vox-cdn.com/thumbor/uraUyO3VeLJ8RJ6ethB54sPF1bs=/0x1:2048x1366/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659802/Dominos_Chevy_Bolt_EVs_08.0.jpg\" /><figcaption><em>Domino’s outfitted Chevy Bolts.</em> | Image: Domino’s</figcaption></figure><p id=\"1PMpbG\">Domino’s is gearing up to put<a href=\"https://ir.dominos.com/news-releases/news-release-details/dominosr-roll-out-nationwide-fleet-800-chevy-boltr-electric\">more than 800 all-electric pizza delivery vehicles into service</a> in the coming months, starting with over 100 of them rolling out in November. The company went with the compact Chevy Bolt EV and is wrapping the vehicles with custom branding but no other bells and whistles — just combustion-free deliveries (via<a href=\"https://electrek.co/2022/11/21/dominos-acquires-800-chevy-bolts-evs-for-delivery-fleet/\"><em>electrek</em></a>).</p><p id=\"Lo1Jmp\">Domino will have a fleet of 855 new electric vehicles, to be exact, and while that’s not quite enough to reach<a href=\"https://ir.dominos.com/static-files/4daec873-268e-4456-b541-3871f28288e2\">all 6,135 of the pizza shops in the US</a>, it's more than the Chevy Spark-based (gas version) ones it built with<a href=\"https://www.theverge.com/2015/10/21/9587270/dominos-dxp-delivery-car-chevy-spark-pizza\">custom pizza warming oven doors</a> in 2015. Those were called the Domino’s DXP, and only 155 of them were made. For the new Bolts, drivers will need to toss the HeatWave bags in...</p><p><a href=\"https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout\">Continue reading&hellip;</a></p></content><link rel=\"alternate\" type=\"text/html\" href=\"https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout\"/><id>https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout</id><author><name>Umar Shakir</name></author></entry></feed>";
            tokens : [Token.Token] = [
                #xmlDeclaration({
                    encoding = ?"UTF-8";
                    version = { major = 1; minor = 0 };
                    standalone = null;
                }),
                #startTag({
                    attributes = [
                        {
                            name = "xmlns";
                            value = ?"http://www.w3.org/2005/Atom";
                        },
                        { name = "xml:lang"; value = ?"en" },
                    ];
                    name = "feed";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [];
                    name = "title";
                    selfClosing = false;
                }),
                #text("The Verge - All Posts"),
                #endTag({ name = "title" }),
                #startTag({
                    attributes = [];
                    name = "icon";
                    selfClosing = false;
                }),
                #text("https://cdn.vox-cdn.com/community_logos/52801/VER_Logomark_32x32..png"),
                #endTag({ name = "icon" }),
                #startTag({
                    attributes = [];
                    name = "updated";
                    selfClosing = false;
                }),
                #text("2022-11-21T21:30:42-05:00"),
                #endTag({ name = "updated" }),
                #startTag({
                    attributes = [];
                    name = "id";
                    selfClosing = false;
                }),
                #text("https://www.theverge.com/rss/full.xml"),
                #endTag({ name = "id" }),
                #startTag({
                    attributes = [{ name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/" }, { name = "rel"; value = ?"alternate" }];
                    name = "link";
                    selfClosing = true;
                }),
                #startTag({
                    attributes = [];
                    name = "entry";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [];
                    name = "published";
                    selfClosing = false;
                }),
                #text("2022-11-21T21:30:42-05:00"),
                #endTag({ name = "published" }),
                #startTag({
                    attributes = [];
                    name = "updated";
                    selfClosing = false;
                }),
                #text("2022-11-21T21:30:42-05:00"),
                #endTag({ name = "updated" }),
                #startTag({
                    attributes = [];
                    name = "title";
                    selfClosing = false;
                }),
                #text("Twitter is making DMs encrypted and adding video, voice chat, per Elon Musk"),
                #endTag({ name = "title" }),
                #startTag({
                    attributes = [{ name = "type"; value = ?"html" }];
                    name = "content";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [];
                    name = "figure";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [{ name = "alt"; value = ?"An illustration of the Twitter logo" }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/6kBqimyOvt-iCvNDVhv2okF4ey4=/0x0:3000x2000/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659917/acastro_STK050_04.0.jpg" }];
                    name = "img";
                    selfClosing = true;
                }),
                #startTag({
                    attributes = [];
                    name = "figcaption";
                    selfClosing = false;
                }),
                #text("Illustration by Alex Castro / The Verge"),
                #endTag({ name = "figcaption" }),
                #endTag({ name = "figure" }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"TvAhZo" }];
                    name = "p";
                    selfClosing = false;
                }),
                #text("Twitter’s new owner, Elon Musk, has been public about his desire to improve how the social network’s direct messages work. In a meeting with employees today, he spelled out exactly what that looks like."),
                #endTag({ name = "p" }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"6MmlUD" }];
                    name = "p";
                    selfClosing = false;
                }),
                #text("Framed by presentation slides titled “Twitter 2.0” at Twitter’s San Fransisco headquarters on Monday, Musk told employees that the company would encrypt DMs and work to add encrypted video and voice calling between accounts, according to a recording of the meeting obtained by"),
                #startTag({
                    attributes = [];
                    name = "em";
                    selfClosing = false;
                }),
                #text("The Verge"),
                #endTag({ name = "em" }),
                #text("."),
                #endTag({ name = "p" }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"Z8NlgY" }];
                    name = "p";
                    selfClosing = false;
                }),
                #text("“We want to enable users to be able to communicate without being concerned about their privacy, [or] without being concerned about a data breach at Twitter causing all of their DMs to hit the web, or think that maybe someone at Twitter could be spying on..."),
                #endTag({ name = "p" }),
                #startTag({
                    attributes = [];
                    name = "p";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("Continue reading&hellip;"),
                #endTag({ name = "a" }),
                #endTag({ name = "p" }),
                #endTag({ name = "content" }),
                #startTag({
                    attributes = [{ name = "rel"; value = ?"alternate" }, { name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling" }];
                    name = "link";
                    selfClosing = true;
                }),
                #startTag({
                    attributes = [];
                    name = "id";
                    selfClosing = false;
                }),
                #text("https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling"),
                #endTag({ name = "id" }),
                #startTag({
                    attributes = [];
                    name = "author";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [];
                    name = "name";
                    selfClosing = false;
                }),
                #text("Alex Heath"),
                #endTag({ name = "name" }),
                #endTag({ name = "author" }),
                #endTag({ name = "entry" }),
                #startTag({
                    attributes = [];
                    name = "entry";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [];
                    name = "published";
                    selfClosing = false;
                }),
                #text("2022-11-21T20:24:25-05:00"),
                #endTag({ name = "published" }),
                #startTag({
                    attributes = [];
                    name = "updated";
                    selfClosing = false;
                }),
                #text("2022-11-21T20:24:25-05:00"),
                #endTag({ name = "updated" }),
                #startTag({
                    attributes = [];
                    name = "title";
                    selfClosing = false;
                }),
                #text("Domino’s is building an all-electric pizza delivery fleet with Chevy Bolts"),
                #endTag({ name = "title" }),
                #startTag({
                    attributes = [{ name = "type"; value = ?"html" }];
                    name = "content";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [];
                    name = "figure";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [{ name = "alt"; value = ?"Two chevy bolt ev cars, wrapped in domino’s artwork are parked in front of a domino’s pizza store with one of the cars hooked up to a charger." }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/uraUyO3VeLJ8RJ6ethB54sPF1bs=/0x1:2048x1366/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659802/Dominos_Chevy_Bolt_EVs_08.0.jpg" }];
                    name = "img";
                    selfClosing = true;
                }),
                #startTag({
                    attributes = [];
                    name = "figcaption";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [];
                    name = "em";
                    selfClosing = false;
                }),
                #text("Domino’s outfitted Chevy Bolts."),
                #endTag({ name = "em" }),
                #text("| Image: Domino’s"),
                #endTag({ name = "figcaption" }),
                #endTag({ name = "figure" }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"1PMpbG" }];
                    name = "p";
                    selfClosing = false;
                }),
                #text("Domino’s is gearing up to put"),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://ir.dominos.com/news-releases/news-release-details/dominosr-roll-out-nationwide-fleet-800-chevy-boltr-electric";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("more than 800 all-electric pizza delivery vehicles into service"),
                #endTag({ name = "a" }),
                #text("in the coming months, starting with over 100 of them rolling out in November. The company went with the compact Chevy Bolt EV and is wrapping the vehicles with custom branding but no other bells and whistles — just combustion-free deliveries (via"),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://electrek.co/2022/11/21/dominos-acquires-800-chevy-bolts-evs-for-delivery-fleet/";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [];
                    name = "em";
                    selfClosing = false;
                }),
                #text("electrek"),
                #endTag({ name = "em" }),
                #endTag({ name = "a" }),
                #text(")."),
                #endTag({ name = "p" }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"Lo1Jmp" }];
                    name = "p";
                    selfClosing = false;
                }),
                #text("Domino will have a fleet of 855 new electric vehicles, to be exact, and while that’s not quite enough to reach"),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://ir.dominos.com/static-files/4daec873-268e-4456-b541-3871f28288e2";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("all 6,135 of the pizza shops in the US"),
                #endTag({ name = "a" }),
                #text(", it's more than the Chevy Spark-based (gas version) ones it built with"),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/2015/10/21/9587270/dominos-dxp-delivery-car-chevy-spark-pizza";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("custom pizza warming oven doors"),
                #endTag({ name = "a" }),
                #text("in 2015. Those were called the Domino’s DXP, and only 155 of them were made. For the new Bolts, drivers will need to toss the HeatWave bags in..."),
                #endTag({ name = "p" }),
                #startTag({
                    attributes = [];
                    name = "p";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("Continue reading&hellip;"),
                #endTag({ name = "a" }),
                #endTag({ name = "p" }),
                #endTag({ name = "content" }),
                #startTag({
                    attributes = [{ name = "rel"; value = ?"alternate" }, { name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout" }];
                    name = "link";
                    selfClosing = true;
                }),
                #startTag({
                    attributes = [];
                    name = "id";
                    selfClosing = false;
                }),
                #text("https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout"),
                #endTag({ name = "id" }),
                #startTag({
                    attributes = [];
                    name = "author";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [];
                    name = "name";
                    selfClosing = false;
                }),
                #text("Umar Shakir"),
                #endTag({ name = "name" }),
                #endTag({ name = "author" }),
                #endTag({ name = "entry" }),
                #endTag({ name = "feed" }),
            ];

            doc : Document.Document = {
                docType = null;
                encoding = ?"UTF-8";
                processInstructions = [];
                root = {
                    attributes = [
                        {
                            name = "xmlns";
                            value = ?"http://www.w3.org/2005/Atom";
                        },
                        { name = "xml:lang"; value = ?"en" },
                    ];
                    children = #open([
                        #element({
                            attributes = [];
                            children = #open([
                                #text("The Verge - All Posts")
                            ]);
                            name = "title";
                        }),
                        #element({
                            attributes = [];
                            children = #open([
                                #text("https://cdn.vox-cdn.com/community_logos/52801/VER_Logomark_32x32..png")
                            ]);
                            name = "icon";
                        }),
                        #element({
                            attributes = [];
                            children = #open([
                                #text("2022-11-21T21:30:42-05:00")
                            ]);
                            name = "updated";
                        }),
                        #element({
                            attributes = [];
                            children = #open([
                                #text("https://www.theverge.com/rss/full.xml")
                            ]);
                            name = "id";
                        }),
                        #element({
                            attributes = [
                                { name = "type"; value = ?"text/html" },
                                {
                                    name = "href";
                                    value = ?"https://www.theverge.com/";
                                },
                                { name = "rel"; value = ?"alternate" },
                            ];
                            children = #selfClosing;
                            name = "link";
                        }),
                        #element({
                            attributes = [];
                            children = #open([
                                #element({
                                    attributes = [];
                                    children = #open([
                                        #text("2022-11-21T21:30:42-05:00")
                                    ]);
                                    name = "published";
                                }),
                                #element({
                                    attributes = [];
                                    children = #open([
                                        #text("2022-11-21T21:30:42-05:00")
                                    ]);
                                    name = "updated";
                                }),
                                #element({
                                    attributes = [];
                                    children = #open([
                                        #text("Twitter is making DMs encrypted and adding video, voice chat, per Elon Musk")
                                    ]);
                                    name = "title";
                                }),
                                #element({
                                    attributes = [{
                                        name = "type";
                                        value = ?"html";
                                    }];
                                    children = #open([
                                        #element({
                                            attributes = [];
                                            children = #open([
                                                #element({
                                                    attributes = [
                                                        {
                                                            name = "alt";
                                                            value = ?"An illustration of the Twitter logo";
                                                        },
                                                        {
                                                            name = "src";
                                                            value = ?"https://cdn.vox-cdn.com/thumbor/6kBqimyOvt-iCvNDVhv2okF4ey4=/0x0:3000x2000/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659917/acastro_STK050_04.0.jpg";
                                                        },
                                                    ];
                                                    children = #selfClosing;
                                                    name = "img";
                                                }),
                                                #element({
                                                    attributes = [];
                                                    children = #open([
                                                        #text("Illustration by Alex Castro / The Verge")
                                                    ]);
                                                    name = "figcaption";
                                                }),
                                            ]);
                                            name = "figure";
                                        }),
                                        #element({
                                            attributes = [{
                                                name = "id";
                                                value = ?"TvAhZo";
                                            }];
                                            children = #open([
                                                #text("Twitter’s new owner, Elon Musk, has been public about his desire to improve how the social network’s direct messages work. In a meeting with employees today, he spelled out exactly what that looks like.")
                                            ]);
                                            name = "p";
                                        }),
                                        #element({
                                            attributes = [{
                                                name = "id";
                                                value = ?"6MmlUD";
                                            }];
                                            children = #open([
                                                #text("Framed by presentation slides titled “Twitter 2.0” at Twitter’s San Fransisco headquarters on Monday, Musk told employees that the company would encrypt DMs and work to add encrypted video and voice calling between accounts, according to a recording of the meeting obtained by"),
                                                #element({
                                                    attributes = [];
                                                    children = #open([
                                                        #text("The Verge")
                                                    ]);
                                                    name = "em";
                                                }),
                                                #text("."),
                                            ]);
                                            name = "p";
                                        }),
                                        #element({
                                            attributes = [{
                                                name = "id";
                                                value = ?"Z8NlgY";
                                            }];
                                            children = #open([
                                                #text("“We want to enable users to be able to communicate without being concerned about their privacy, [or] without being concerned about a data breach at Twitter causing all of their DMs to hit the web, or think that maybe someone at Twitter could be spying on...")
                                            ]);
                                            name = "p";
                                        }),
                                        #element({
                                            attributes = [];
                                            children = #open([
                                                #element({
                                                    attributes = [{
                                                        name = "href";
                                                        value = ?"https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling";
                                                    }];
                                                    children = #open([
                                                        #text("Continue reading&hellip;")
                                                    ]);
                                                    name = "a";
                                                })
                                            ]);
                                            name = "p";
                                        }),
                                    ]);
                                    name = "content";
                                }),
                                #element({
                                    attributes = [
                                        { name = "rel"; value = ?"alternate" },
                                        { name = "type"; value = ?"text/html" },
                                        {
                                            name = "href";
                                            value = ?"https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling";
                                        },
                                    ];
                                    children = #selfClosing;
                                    name = "link";
                                }),
                                #element({
                                    attributes = [];
                                    children = #open([
                                        #text("https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling")
                                    ]);
                                    name = "id";
                                }),
                                #element({
                                    attributes = [];
                                    children = #open([
                                        #element({
                                            attributes = [];
                                            children = #open([
                                                #text("Alex Heath")
                                            ]);
                                            name = "name";
                                        })
                                    ]);
                                    name = "author";
                                }),
                            ]);
                            name = "entry";
                        }),
                        #element({
                            attributes = [];
                            children = #open([
                                #element({
                                    attributes = [];
                                    children = #open([
                                        #text("2022-11-21T20:24:25-05:00")
                                    ]);
                                    name = "published";
                                }),
                                #element({
                                    attributes = [];
                                    children = #open([
                                        #text("2022-11-21T20:24:25-05:00")
                                    ]);
                                    name = "updated";
                                }),
                                #element({
                                    attributes = [];
                                    children = #open([
                                        #text("Domino’s is building an all-electric pizza delivery fleet with Chevy Bolts")
                                    ]);
                                    name = "title";
                                }),
                                #element({
                                    attributes = [{
                                        name = "type";
                                        value = ?"html";
                                    }];
                                    children = #open([
                                        #element({
                                            attributes = [];
                                            children = #open([
                                                #element({
                                                    attributes = [
                                                        {
                                                            name = "alt";
                                                            value = ?"Two chevy bolt ev cars, wrapped in domino’s artwork are parked in front of a domino’s pizza store with one of the cars hooked up to a charger.";
                                                        },
                                                        {
                                                            name = "src";
                                                            value = ?"https://cdn.vox-cdn.com/thumbor/uraUyO3VeLJ8RJ6ethB54sPF1bs=/0x1:2048x1366/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659802/Dominos_Chevy_Bolt_EVs_08.0.jpg";
                                                        },
                                                    ];
                                                    children = #selfClosing;
                                                    name = "img";
                                                }),
                                                #element({
                                                    attributes = [];
                                                    children = #open([
                                                        #element({
                                                            attributes = [];
                                                            children = #open([
                                                                #text("Domino’s outfitted Chevy Bolts.")
                                                            ]);
                                                            name = "em";
                                                        }),
                                                        #text("| Image: Domino’s"),
                                                    ]);
                                                    name = "figcaption";
                                                }),
                                            ]);
                                            name = "figure";
                                        }),
                                        #element({
                                            attributes = [{
                                                name = "id";
                                                value = ?"1PMpbG";
                                            }];
                                            children = #open([
                                                #text("Domino’s is gearing up to put"),
                                                #element({
                                                    attributes = [{
                                                        name = "href";
                                                        value = ?"https://ir.dominos.com/news-releases/news-release-details/dominosr-roll-out-nationwide-fleet-800-chevy-boltr-electric";
                                                    }];
                                                    children = #open([
                                                        #text("more than 800 all-electric pizza delivery vehicles into service")
                                                    ]);
                                                    name = "a";
                                                }),
                                                #text("in the coming months, starting with over 100 of them rolling out in November. The company went with the compact Chevy Bolt EV and is wrapping the vehicles with custom branding but no other bells and whistles — just combustion-free deliveries (via"),
                                                #element({
                                                    attributes = [{
                                                        name = "href";
                                                        value = ?"https://electrek.co/2022/11/21/dominos-acquires-800-chevy-bolts-evs-for-delivery-fleet/";
                                                    }];
                                                    children = #open([
                                                        #element({
                                                            attributes = [];
                                                            children = #open([
                                                                #text("electrek")
                                                            ]);
                                                            name = "em";
                                                        })
                                                    ]);
                                                    name = "a";
                                                }),
                                                #text(")."),
                                            ]);
                                            name = "p";
                                        }),
                                        #element({
                                            attributes = [{
                                                name = "id";
                                                value = ?"Lo1Jmp";
                                            }];
                                            children = #open([
                                                #text("Domino will have a fleet of 855 new electric vehicles, to be exact, and while that’s not quite enough to reach"),
                                                #element({
                                                    attributes = [{
                                                        name = "href";
                                                        value = ?"https://ir.dominos.com/static-files/4daec873-268e-4456-b541-3871f28288e2";
                                                    }];
                                                    children = #open([
                                                        #text("all 6,135 of the pizza shops in the US")
                                                    ]);
                                                    name = "a";
                                                }),
                                                #text(", it's more than the Chevy Spark-based (gas version) ones it built with"),
                                                #element({
                                                    attributes = [{
                                                        name = "href";
                                                        value = ?"https://www.theverge.com/2015/10/21/9587270/dominos-dxp-delivery-car-chevy-spark-pizza";
                                                    }];
                                                    children = #open([
                                                        #text("custom pizza warming oven doors")
                                                    ]);
                                                    name = "a";
                                                }),
                                                #text("in 2015. Those were called the Domino’s DXP, and only 155 of them were made. For the new Bolts, drivers will need to toss the HeatWave bags in..."),
                                            ]);
                                            name = "p";
                                        }),
                                        #element({
                                            attributes = [];
                                            children = #open([
                                                #element({
                                                    attributes = [{
                                                        name = "href";
                                                        value = ?"https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout";
                                                    }];
                                                    children = #open([
                                                        #text("Continue reading&hellip;")
                                                    ]);
                                                    name = "a";
                                                })
                                            ]);
                                            name = "p";
                                        }),
                                    ]);
                                    name = "content";
                                }),
                                #element({
                                    attributes = [
                                        { name = "rel"; value = ?"alternate" },
                                        { name = "type"; value = ?"text/html" },
                                        {
                                            name = "href";
                                            value = ?"https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout";
                                        },
                                    ];
                                    children = #selfClosing;
                                    name = "link";
                                }),
                                #element({
                                    attributes = [];
                                    children = #open([
                                        #text("https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout")
                                    ]);
                                    name = "id";
                                }),
                                #element({
                                    attributes = [];
                                    children = #open([
                                        #element({
                                            attributes = [];
                                            children = #open([
                                                #text("Umar Shakir")
                                            ]);
                                            name = "name";
                                        })
                                    ]);
                                    name = "author";
                                }),
                            ]);
                            name = "entry";
                        }),
                    ]);
                    name = "feed";
                };
                standalone = null;
                version = ?{ major = 1; minor = 0 };
            };
            processedElement = {
                attributes = [
                    { name = "xmlns"; value = ?"http://www.w3.org/2005/Atom" },
                    { name = "xml:lang"; value = ?"en" },
                ];
                children = #open([
                    #element({
                        attributes = [];
                        children = #open([#text("The Verge - All Posts")]);
                        name = "title";
                    }),
                    #element({
                        attributes = [];
                        children = #open([
                            #text("https://cdn.vox-cdn.com/community_logos/52801/VER_Logomark_32x32..png")
                        ]);
                        name = "icon";
                    }),
                    #element({
                        attributes = [];
                        children = #open([#text("2022-11-21T21:30:42-05:00")]);
                        name = "updated";
                    }),
                    #element({
                        attributes = [];
                        children = #open([
                            #text("https://www.theverge.com/rss/full.xml")
                        ]);
                        name = "id";
                    }),
                    #element({
                        attributes = [
                            { name = "type"; value = ?"text/html" },
                            {
                                name = "href";
                                value = ?"https://www.theverge.com/";
                            },
                            { name = "rel"; value = ?"alternate" },
                        ];
                        children = #selfClosing;
                        name = "link";
                    }),
                    #element({
                        attributes = [];
                        children = #open([
                            #element({
                                attributes = [];
                                children = #open([#text("2022-11-21T21:30:42-05:00")]);
                                name = "published";
                            }),
                            #element({
                                attributes = [];
                                children = #open([#text("2022-11-21T21:30:42-05:00")]);
                                name = "updated";
                            }),
                            #element({
                                attributes = [];
                                children = #open([#text("Twitter is making DMs encrypted and adding video, voice chat, per Elon Musk")]);
                                name = "title";
                            }),
                            #element({
                                attributes = [{ name = "type"; value = ?"html" }];
                                children = #open([
                                    #element({
                                        attributes = [];
                                        children = #open([
                                            #element({
                                                attributes = [
                                                    {
                                                        name = "alt";
                                                        value = ?"An illustration of the Twitter logo";
                                                    },
                                                    {
                                                        name = "src";
                                                        value = ?"https://cdn.vox-cdn.com/thumbor/6kBqimyOvt-iCvNDVhv2okF4ey4=/0x0:3000x2000/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659917/acastro_STK050_04.0.jpg";
                                                    },
                                                ];
                                                children = #selfClosing;
                                                name = "img";
                                            }),
                                            #element({
                                                attributes = [];
                                                children = #open([#text("Illustration by Alex Castro / The Verge")]);
                                                name = "figcaption";
                                            }),
                                        ]);
                                        name = "figure";
                                    }),
                                    #element({
                                        attributes = [{
                                            name = "id";
                                            value = ?"TvAhZo";
                                        }];
                                        children = #open([
                                            #text("Twitter’s new owner, Elon Musk, has been public about his desire to improve how the social network’s direct messages work. In a meeting with employees today, he spelled out exactly what that looks like.")
                                        ]);
                                        name = "p";
                                    }),
                                    #element({
                                        attributes = [{
                                            name = "id";
                                            value = ?"6MmlUD";
                                        }];
                                        children = #open([
                                            #text("Framed by presentation slides titled “Twitter 2.0” at Twitter’s San Fransisco headquarters on Monday, Musk told employees that the company would encrypt DMs and work to add encrypted video and voice calling between accounts, according to a recording of the meeting obtained by"),
                                            #element({
                                                attributes = [];
                                                children = #open([#text("The Verge")]);
                                                name = "em";
                                            }),
                                            #text("."),
                                        ]);
                                        name = "p";
                                    }),
                                    #element({
                                        attributes = [{
                                            name = "id";
                                            value = ?"Z8NlgY";
                                        }];
                                        children = #open([
                                            #text("“We want to enable users to be able to communicate without being concerned about their privacy, [or] without being concerned about a data breach at Twitter causing all of their DMs to hit the web, or think that maybe someone at Twitter could be spying on...")
                                        ]);
                                        name = "p";
                                    }),
                                    #element({
                                        attributes = [];
                                        children = #open([
                                            #element({
                                                attributes = [{
                                                    name = "href";
                                                    value = ?"https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling";
                                                }];
                                                children = #open([#text("Continue reading&hellip;")]);
                                                name = "a";
                                            })
                                        ]);
                                        name = "p";
                                    }),
                                ]);
                                name = "content";
                            }),
                            #element({
                                attributes = [
                                    { name = "rel"; value = ?"alternate" },
                                    { name = "type"; value = ?"text/html" },
                                    {
                                        name = "href";
                                        value = ?"https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling";
                                    },
                                ];
                                children = #selfClosing;
                                name = "link";
                            }),
                            #element({
                                attributes = [];
                                children = #open([#text("https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling")]);
                                name = "id";
                            }),
                            #element({
                                attributes = [];
                                children = #open([
                                    #element({
                                        attributes = [];
                                        children = #open([#text("Alex Heath")]);
                                        name = "name";
                                    })
                                ]);
                                name = "author";
                            }),
                        ]);
                        name = "entry";
                    }),
                    #element({
                        attributes = [];
                        children = #open([
                            #element({
                                attributes = [];
                                children = #open([#text("2022-11-21T20:24:25-05:00")]);
                                name = "published";
                            }),
                            #element({
                                attributes = [];
                                children = #open([#text("2022-11-21T20:24:25-05:00")]);
                                name = "updated";
                            }),
                            #element({
                                attributes = [];
                                children = #open([#text("Domino’s is building an all-electric pizza delivery fleet with Chevy Bolts")]);
                                name = "title";
                            }),
                            #element({
                                attributes = [{ name = "type"; value = ?"html" }];
                                children = #open([
                                    #element({
                                        attributes = [];
                                        children = #open([
                                            #element({
                                                attributes = [
                                                    {
                                                        name = "alt";
                                                        value = ?"Two chevy bolt ev cars, wrapped in domino’s artwork are parked in front of a domino’s pizza store with one of the cars hooked up to a charger.";
                                                    },
                                                    {
                                                        name = "src";
                                                        value = ?"https://cdn.vox-cdn.com/thumbor/uraUyO3VeLJ8RJ6ethB54sPF1bs=/0x1:2048x1366/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659802/Dominos_Chevy_Bolt_EVs_08.0.jpg";
                                                    },
                                                ];
                                                children = #selfClosing;
                                                name = "img";
                                            }),
                                            #element({
                                                attributes = [];
                                                children = #open([
                                                    #element({
                                                        attributes = [];
                                                        children = #open([#text("Domino’s outfitted Chevy Bolts.")]);
                                                        name = "em";
                                                    }),
                                                    #text("| Image: Domino’s"),
                                                ]);
                                                name = "figcaption";
                                            }),
                                        ]);
                                        name = "figure";
                                    }),
                                    #element({
                                        attributes = [{
                                            name = "id";
                                            value = ?"1PMpbG";
                                        }];
                                        children = #open([
                                            #text("Domino’s is gearing up to put"),
                                            #element({
                                                attributes = [{
                                                    name = "href";
                                                    value = ?"https://ir.dominos.com/news-releases/news-release-details/dominosr-roll-out-nationwide-fleet-800-chevy-boltr-electric";
                                                }];
                                                children = #open([#text("more than 800 all-electric pizza delivery vehicles into service")]);
                                                name = "a";
                                            }),
                                            #text("in the coming months, starting with over 100 of them rolling out in November. The company went with the compact Chevy Bolt EV and is wrapping the vehicles with custom branding but no other bells and whistles — just combustion-free deliveries (via"),
                                            #element({
                                                attributes = [{
                                                    name = "href";
                                                    value = ?"https://electrek.co/2022/11/21/dominos-acquires-800-chevy-bolts-evs-for-delivery-fleet/";
                                                }];
                                                children = #open([#element({ attributes = []; children = #open([#text("electrek")]); name = "em" })]);
                                                name = "a";
                                            }),
                                            #text(")."),
                                        ]);
                                        name = "p";
                                    }),
                                    #element({
                                        attributes = [{
                                            name = "id";
                                            value = ?"Lo1Jmp";
                                        }];
                                        children = #open([
                                            #text("Domino will have a fleet of 855 new electric vehicles, to be exact, and while that’s not quite enough to reach"),
                                            #element({
                                                attributes = [{
                                                    name = "href";
                                                    value = ?"https://ir.dominos.com/static-files/4daec873-268e-4456-b541-3871f28288e2";
                                                }];
                                                children = #open([#text("all 6,135 of the pizza shops in the US")]);
                                                name = "a";
                                            }),
                                            #text(", it's more than the Chevy Spark-based (gas version) ones it built with"),
                                            #element({
                                                attributes = [{
                                                    name = "href";
                                                    value = ?"https://www.theverge.com/2015/10/21/9587270/dominos-dxp-delivery-car-chevy-spark-pizza";
                                                }];
                                                children = #open([#text("custom pizza warming oven doors")]);
                                                name = "a";
                                            }),
                                            #text("in 2015. Those were called the Domino’s DXP, and only 155 of them were made. For the new Bolts, drivers will need to toss the HeatWave bags in..."),
                                        ]);
                                        name = "p";
                                    }),
                                    #element({
                                        attributes = [];
                                        children = #open([
                                            #element({
                                                attributes = [{
                                                    name = "href";
                                                    value = ?"https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout";
                                                }];
                                                children = #open([#text("Continue reading&hellip;")]);
                                                name = "a";
                                            })
                                        ]);
                                        name = "p";
                                    }),
                                ]);
                                name = "content";
                            }),
                            #element({
                                attributes = [
                                    { name = "rel"; value = ?"alternate" },
                                    { name = "type"; value = ?"text/html" },
                                    {
                                        name = "href";
                                        value = ?"https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout";
                                    },
                                ];
                                children = #selfClosing;
                                name = "link";
                            }),
                            #element({
                                attributes = [];
                                children = #open([
                                    #text("https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout")
                                ]);
                                name = "id";
                            }),
                            #element({
                                attributes = [];
                                children = #open([
                                    #element({
                                        attributes = [];
                                        children = #open([#text("Umar Shakir")]);
                                        name = "name";
                                    })
                                ]);
                                name = "author";
                            }),
                        ]);
                        name = "entry";
                    }),
                ]);
                name = "feed";
            };
        },
    ];

    public type TokenizingFailExample = {
        name : Text;
        error : Text;
        rawXml : Text;
    };

    public let TokenizingFailureExamples : [TokenizingFailExample] = [
        {
            name = "Missing opening tag character";
            error = "Unexpected character '>'";
            rawXml = "root></root>";
        },
        {
            name = "Extra closing tag character";
            error = "Unexpected character '<'";
            rawXml = "<root><</root>";
        },
        {
            name = "Extra opening tag character";
            error = "Unexpected character '>'";
            rawXml = "<root>></root>";
        },
    ];

    public type ParsingFailExample = {
        name : Text;
        error : Parser.ParseError;
        tokens : [Token.Token];
    };

    public let parsingFailureExamples : [ParsingFailExample] = [
        {
            name = "Tokens after root";
            error = #tokensAfterRoot;
            tokens = [
                #startTag({
                    attributes = [];
                    name = "root1";
                    selfClosing = false;
                }),
                #endTag({ name = "root1" }),
                #startTag({
                    attributes = [];
                    name = "root2";
                    selfClosing = false;
                }),
                #endTag({ name = "root2" }),
            ];
        },
        {
            name = "Empty";
            error = #unexpectedEndOfTokens;
            tokens = [];
        },
        {
            name = "Only xml declaration";
            error = #unexpectedEndOfTokens;
            tokens = [
                #xmlDeclaration({
                    encoding = null;
                    standalone = null;
                    version = { major = 1; minor = 0 };
                }),
            ];
        },
    ];

};
