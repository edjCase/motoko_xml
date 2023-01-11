import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Utf8 "Utf8";

module {
    public type File = {
        version : Text;
        encoding : Text;
        root : Node;
    };

    public type Node = {
        name : Text;
        attributes : [Attribute];
        children : { #selfClosing; #open : [NodeOrText] };
    };

    public type NodeOrText = {
        #node : Node;
        #text : Text;
    };

    public type Attribute = {
        name : Text;
        value : ?Text;
    };

    public func parseFileBytes(bytes : Blob) : {
        #ok : File;
        #err : { reader : UTF8Reader; tokens : [XMLToken] };
    } {
        let reader = UTF8Reader(bytes);
        switch (parseFileText(reader)) {
            case (#err(tokens)) #err({ reader = reader; tokens = tokens });
            case (#ok(f)) #ok(f);
        };
    };

    public func nextWord() : ?Text {
        var inQuotes = false;
        do ? {
            let wordBuffer = Buffer.Buffer<Char>(1);
            loop {
                let p = peek();
                if (p == null or (not inQuotes and (isWhitespace(p) or p == ?'<' or p == ?'>' or p == ?'/' or p == ?'?'))) {
                    if (wordBuffer.size() > 0) {
                        // Return word
                        return ?Text.fromIter(wordBuffer.vals());
                    };
                    switch (p) {
                        case (null) return null;
                        case (?p) return ?Text.fromChar(p);
                    };
                } else {
                    let quoteChar = Text.toIter("\"").next(); // TODO how to do '\"'??
                    wordBuffer.add(next()!);
                    if (p == quoteChar) {
                        if (not inQuotes) {
                            inQuotes := true;
                        } else {
                            // End of quotes is end of word
                            return ?Text.fromIter(wordBuffer.vals());
                        };
                    };
                };
            };
        };
    };

    public func parseFileText(reader : UTF8Reader) : {
        #ok : File;
        #err : [XMLToken];
    } {
        let xmlReader = XMLReader(reader);
        let tokens : [XMLToken] = switch (xmlReader.get()) {
            case (#ok(t)) t;
            case (#err(t)) return #err(t);
        };
        let a = do ? {
            if (tokens.size() < 2) {
                return #err(tokens);
            };
            let tokenIter = Iter.fromArray(tokens);
            let headerTag = switch (tokenIter.next()!) {
                case (#text(txt)) {
                    return #err(tokens); // Invalid
                };
                case (#tag(tag)) tag;
            };
            let version : Text = switch (Array.find<Attribute>(headerTag.attributes, func(a) { a.name == "version" })) {
                case (null) return #err(tokens); // TODO default version?
                case (?v) v.value!;
            };
            let encoding : Text = switch (Array.find<Attribute>(headerTag.attributes, func(a) { a.name == "encoding" })) {
                case (null) return #err(tokens); // TODO default encoding?
                case (?v) v.value!;
            };
            let root = switch (buildXml(tokenIter)) {
                case (null) return #err(tokens);
                case (?#node(n)) n;
                case (?#text(t)) return #err(tokens);
            };
            {
                version = version;
                encoding = encoding;
                root = root;
            };
        };
        switch (a) {
            case (null) #err(tokens);
            case (?a) #ok(a);
        };
    };

    private func buildXml(i : Iter.Iter<XMLToken>) : ?NodeOrText {
        do ? {
            switch (i.next()) {
                case (?#tag(tag)) {
                    return ?#node(buildNode(i, tag)!);
                };
                case (?#text(txt)) {
                    return ?#text(txt);
                };
                case (null) {
                    return null;
                };
            };
        };
    };

    private func buildNode(i : Iter.Iter<XMLToken>, startTag : Tag) : ?Node {
        do ? {
            switch (startTag.style) {
                case (#closing) return null;
                case (#selfClosing) return ?{
                    name = startTag.name;
                    attributes = startTag.attributes;
                    children = #selfClosing;
                };
                case (#opening) {
                    let children = Buffer.Buffer<NodeOrText>(1);
                    label l loop {
                        let next = i.next()!;
                        switch (next) {
                            case (#tag(tag)) {
                                let n = switch (tag.style) {
                                    case (#opening or #selfClosing) {
                                        buildNode(i, tag)!;
                                    };
                                    case (#closing) {
                                        if (tag.name == startTag.name) {
                                            // Tag is closed
                                            break l;
                                        };
                                        return null; // Invalid
                                    };
                                };
                                children.add(#node(n));
                            };
                            case (#text(t)) {
                                children.add(#text(t));
                            };
                        };
                    };
                    return ?{
                        name = startTag.name;
                        attributes = startTag.attributes;
                        children = #open(Buffer.toArray(children));
                    };
                };
            };
        };
    };

    // <?xml version="1.0" encoding="UTF-8"?>
    // <feed
    //     xmlns="http://www.w3.org/2005/Atom" xml:lang="en">
    //     <title>The Verge - All Posts</title>
    //     <icon>https://cdn.vox-cdn.com/community_logos/52801/VER_Logomark_32x32..png</icon>
    //     <updated>2022-11-21T21:30:42-05:00</updated>
    //     <id>https://www.theverge.com/rss/full.xml</id>
    //     <link type="text/html" href="https://www.theverge.com/" rel="alternate"/>
    //     <entry>
    //         <published>2022-11-21T21:30:42-05:00</published>
    //         <updated>2022-11-21T21:30:42-05:00</updated>
    //         <title>Twitter is making DMs encrypted and adding video, voice chat, per Elon Musk</title>
    //         <content type="html">
    //             <figure>
    //                 <img alt="An illustration of the Twitter logo" src="https://cdn.vox-cdn.com/thumbor/6kBqimyOvt-iCvNDVhv2okF4ey4=/0x0:3000x2000/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659917/acastro_STK050_04.0.jpg" />
    //                 <figcaption>Illustration by Alex Castro / The Verge</figcaption>
    //             </figure>
    //             <p id="TvAhZo">Twitter’s new owner, Elon Musk, has been public about his desire to improve how the social network’s direct messages work. In a meeting with employees today, he spelled out exactly what that looks like.</p>
    //             <p id="6MmlUD">Framed by presentation slides titled “Twitter 2.0” at Twitter’s San Fransisco headquarters on Monday, Musk told employees that the company would encrypt DMs and work to add encrypted video and voice calling between accounts, according to a recording of the meeting obtained by
    //                 <em>The Verge</em>.
    //             </p>
    //             <p id="Z8NlgY">“We want to enable users to be able to communicate without being concerned about their privacy, [or] without being concerned about a data breach at Twitter causing all of their DMs to hit the web, or think that maybe someone at Twitter could be spying on...</p>
    //             <p>
    //                 <a href="https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling">Continue reading&hellip;</a>
    //             </p>
    //         </content>
    //         <link rel="alternate" type="text/html" href="https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling"/>
    //         <id>https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling</id>
    //         <author>
    //             <name>Alex Heath</name>
    //         </author>
    //     </entry>
    //     <entry>
    //         <published>2022-11-21T20:24:25-05:00</published>
    //         <updated>2022-11-21T20:24:25-05:00</updated>
    //         <title>Domino’s is building an all-electric pizza delivery fleet with Chevy Bolts</title>
    //         <content type="html">
    //             <figure>
    //                 <img alt="Two chevy bolt ev cars, wrapped in domino’s artwork are parked in front of a domino’s pizza store with one of the cars hooked up to a charger." src="https://cdn.vox-cdn.com/thumbor/uraUyO3VeLJ8RJ6ethB54sPF1bs=/0x1:2048x1366/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659802/Dominos_Chevy_Bolt_EVs_08.0.jpg" />
    //                 <figcaption>
    //                     <em>Domino’s outfitted Chevy Bolts.</em> | Image: Domino’s
    //                 </figcaption>
    //             </figure>
    //             <p id="1PMpbG">Domino’s is gearing up to put
    //                 <a href="https://ir.dominos.com/news-releases/news-release-details/dominosr-roll-out-nationwide-fleet-800-chevy-boltr-electric">more than 800 all-electric pizza delivery vehicles into service</a> in the coming months, starting with over 100 of them rolling out in November. The company went with the compact Chevy Bolt EV and is wrapping the vehicles with custom branding but no other bells and whistles — just combustion-free deliveries (via
    //                 <a href="https://electrek.co/2022/11/21/dominos-acquires-800-chevy-bolts-evs-for-delivery-fleet/">
    //                     <em>electrek</em>
    //                 </a>).
    //             </p>
    //             <p id="Lo1Jmp">Domino will have a fleet of 855 new electric vehicles, to be exact, and while that’s not quite enough to reach
    //                 <a href="https://ir.dominos.com/static-files/4daec873-268e-4456-b541-3871f28288e2">all 6,135 of the pizza shops in the US</a>, it's more than the Chevy Spark-based (gas version) ones it built with
    //                 <a href="https://www.theverge.com/2015/10/21/9587270/dominos-dxp-delivery-car-chevy-spark-pizza">custom pizza warming oven doors</a> in 2015. Those were called the Domino’s DXP, and only 155 of them were made. For the new Bolts, drivers will need to toss the HeatWave bags in...
    //             </p>
    //             <p>
    //                 <a href="https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout">Continue reading&hellip;</a>
    //             </p>
    //         </content>
    //         <link rel="alternate" type="text/html" href="https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout"/>
    //         <id>https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout</id>
    //         <author>
    //             <name>Umar Shakir</name>
    //         </author>
    //     </entry>
    //     <entry>
    //         <published>2022-11-21T19:44:46-05:00</published>
    //         <updated>2022-11-21T19:44:46-05:00</updated>
    //         <title>Elon Musk bought Twitter, and here’s everything that happened next</title>
    //         <content type="html">
    //             <figure>
    //                 <img alt="" src="https://cdn.vox-cdn.com/thumbor/gOLos_N33sgfTa2gWSVdcAxcqt0=/0x0:2040x1360/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/70735423/STK171_VRG_Illo_5_Normand_ElonMusk_05.5.jpg" />
    //                 <figcaption>Laura Normand / The Verge</figcaption>
    //             </figure>
    //             <p>Elon Musk is now the owner, CEO, and sole director of Twitter. His “Twitter 2.0” era has so far included mass layoffs and rapidly changing policy decisions.</p>
    //             <p>
    //                 <a href="https://www.theverge.com/2022/4/11/23019836/elon-musk-twitter-board-of-directors-news-updates">Continue reading&hellip;</a>
    //             </p>
    //         </content>
    //         <link rel="alternate" type="text/html" href="https://www.theverge.com/2022/4/11/23019836/elon-musk-twitter-board-of-directors-news-updates"/>
    //         <id>https://www.theverge.com/2022/4/11/23019836/elon-musk-twitter-board-of-directors-news-updates</id>
    //         <author>
    //             <name>Alex Heath</name>
    //             <name>Emma Roth</name>
    //             <name>James Vincent</name>
    //             <name>Sean Hollister</name>
    //             <name>Nilay Patel</name>
    //             <name>Mitchell Clark</name>
    //             <name>Richard Lawler</name>
    //             <name>Russell Brandom</name>
    //             <name>Elizabeth Lopatto</name>
    //             <name>Thomas Ricker</name>
    //             <name>Mia Sato</name>
    //         </author>
    //     </entry>
    //     <entry>
    //         <published>2022-11-21T19:31:11-05:00</published>
    //         <updated>2022-11-21T19:31:11-05:00</updated>
    //         <title>Twitter won’t restart paid verification until ‘significant impersonations’ stop, Elon Musk says</title>
    //         <content type="html">
    //             <figure>
    //                 <img alt="An illustration of the Twitter logo." src="https://cdn.vox-cdn.com/thumbor/zQLVeU7EwVTBQLHivgfUFyqWqvM=/0x0:3000x2000/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659669/acastro_STK050_06.5.jpg" />
    //                 <figcaption>Illustration by Alex Castro / The Verge</figcaption>
    //             </figure>
    //             <p id="InvXEX">Elon Musk told Twitter employees on Monday that the company won’t relaunch its paid verification subscription, Twitter Blue, until “we’re confident about significant impersonations not happening,” according to a recording of his remarks obtained by
    //                 <em>The Verge</em>.
    //             </p>
    //             <p id="iN7NAx">Musk said last week that his $8 per month Blue subscription
    //                 <a href="https://www.theverge.com/2022/11/15/23461244/twitter-blue-relaunch-verification-elon-musk">would be made available again on November 29th</a>. But in the meeting with employees, he said the timing of the launch was unclear: “We might launch it next week. We might not. But we’re not going to launch until there’s high confidence in protecting against those significant impersonations.”
    //             </p>
    //             <p id="Le0vLW">After taking over Twitter, Musk’s first big change was to quickly introduce the ability for users to buy a blue checkmark through...</p>
    //             <p>
    //                 <a href="https://www.theverge.com/2022/11/21/23472184/elon-musk-twitter-paid-verification-relaunch-delay-impersonations">Continue reading&hellip;</a>
    //             </p>
    //         </content>
    //         <link rel="alternate" type="text/html" href="https://www.theverge.com/2022/11/21/23472184/elon-musk-twitter-paid-verification-relaunch-delay-impersonations"/>
    //         <id>https://www.theverge.com/2022/11/21/23472184/elon-musk-twitter-paid-verification-relaunch-delay-impersonations</id>
    //         <author>
    //             <name>Alex Heath</name>
    //         </author>
    //     </entry>
    //     <entry>
    //         <published>2022-11-21T19:00:00-05:00</published>
    //         <updated>2022-11-21T19:00:00-05:00</updated>
    //         <title>Apple changed how reading books works in iOS 16, and I may never be happy again</title>
    //         <content type="html">
    //             <figure>
    //                 <img alt="Nilay Patel holds an iPhone 14 Pro in his hands." src="https://cdn.vox-cdn.com/thumbor/fy-1OSl08rP0neOAsPVBx3gB7kM=/0x0:2040x1360/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659548/226270_iPHONE_14_PHO_akrales_0030.0.jpg" />
    //                 <figcaption>
    //                     <em>Am I being dramatic? Yes. Has this change made me read on my phone less? Also yes.</em> | Photo by Amelia Holowaty Krales / The Verge
    //                 </figcaption>
    //             </figure>
    //             <p id="NwS67V">Apple Books has been my main reading app for years for one very specific reason: its page-turning animation is far and away the best in the business. Unfortunately, that went away with iOS 16 and has been replaced by a new animation that makes it feel like you’re moving cards through a deck instead of leafing through a digitized version of paper. And despite the fact that I’ve been trying to get used to the change since I got onto the beta in July, I still feel like Apple’s destroyed one of the last ways that my phone brought joy into my life.</p>
    //             <p id="ed6BLz">For those unfamiliar with Apple’s Books app (formerly known as iBooks), I’ll try to explain the hole that’s suddenly been punched into my reading life. Before iOS 16, the app would play a...</p>
    //             <p>
    //                 <a href="https://www.theverge.com/2022/11/21/23471306/apple-books-ios-16-page-flip-animation-sucks">Continue reading&hellip;</a>
    //             </p>
    //         </content>
    //         <link rel="alternate" type="text/html" href="https://www.theverge.com/2022/11/21/23471306/apple-books-ios-16-page-flip-animation-sucks"/>
    //         <id>https://www.theverge.com/2022/11/21/23471306/apple-books-ios-16-page-flip-animation-sucks</id>
    //         <author>
    //             <name>Mitchell Clark</name>
    //         </author>
    //     </entry>
    //     <entry>
    //         <published>2022-11-21T18:46:49-05:00</published>
    //         <updated>2022-11-21T18:46:49-05:00</updated>
    //         <title>iOS developers say Apple’s App Store analytics aren’t anonymous</title>
    //         <content type="html">
    //             <figure>
    //                 <img alt="" src="https://cdn.vox-cdn.com/thumbor/eYqZ0c_m283srxzRlmzfjkoh_pQ=/119x0:1952x1222/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659501/Screenshot_2022_11_21_at_14.03.07.0.png" />
    //                 <figcaption>Image: Apple</figcaption>
    //             </figure>
    //             <p id="xinbTn">The detailed analytics data Apple records about what you do in the App Store can be tied directly to your Apple account, according to app development and research team Mysk. In
    //                 <a href="https://twitter.com/mysk_co/status/1594515229915979776">a Twitter thread</a>, Mysk shows that Apple sends what’s known as a “Directory Services Identifier” along with its App Store analytics info and argues that the identifier is also tied to your iCloud account, linking your name, email address, and more.
    //             </p>
    //             <p id="zrD2cY">The thread also notes that the data is still sent even if you turn off device analytics in settings, and that Apple sends your DSID in other apps as well. In the last tweet in the thread, Mysk says: “You just need to know three things: 1- The App Store sends detailed analytics about you to Apple. 2- There’s no way to...</p>
    //             <p>
    //                 <a href="https://www.theverge.com/2022/11/21/23471827/apple-app-store-data-collection-analytics-personal-info-privacy">Continue reading&hellip;</a>
    //             </p>
    //         </content>
    //         <link rel="alternate" type="text/html" href="https://www.theverge.com/2022/11/21/23471827/apple-app-store-data-collection-analytics-personal-info-privacy"/>
    //         <id>https://www.theverge.com/2022/11/21/23471827/apple-app-store-data-collection-analytics-personal-info-privacy</id>
    //         <author>
    //             <name>Mitchell Clark</name>
    //         </author>
    //     </entry>
    //     <entry>
    //         <published>2022-11-21T18:03:32-05:00</published>
    //         <updated>2022-11-21T18:03:32-05:00</updated>
    //         <title>Bob Iger steps back in as Disney CEO, replacing Bob Chapek </title>
    //         <content type="html">
    //             <figure>
    //                 <img alt="A colorful graphical illustration of the Disney Plus logo." src="https://cdn.vox-cdn.com/thumbor/LBZpzWdUUjxgvybEwhbunWt_HHw=/0x0:2040x1360/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71655348/acastro_STK080_disneyPlus_02.0.jpg" />
    //                 <figcaption>Illustration by Alex Castro / The Verge</figcaption>
    //             </figure>
    //             <p id="SOoXw3">In a sudden turn of events, Disney has reversed
    //                 <a href="https://www.theverge.com/2020/2/25/21153317/bob-iger-disney-ceo-steps-down-chapek-kevin-mayer-parks-products-succession">the CEO swap that surprised us in early 2020</a>, with Bob Iger
    //                 <a href="https://thewaltdisneycompany.com/the-walt-disney-company-board-of-directors-appoints-robert-a-iger-as-chief-executive-officer/">returning to his post</a>, replacing his own successor, Bob Chapek. Iger, who is also the company’s largest shareholder, is now set to serve a new two-year term as CEO. Part of Iger’s job in those two years will be to pick and groom his long-term successor.
    //             </p>
    //             <p id="v6tlhA">Of course, Chapek was an Iger choice too. Chapek
    //                 <a href="https://www.theverge.com/2020/2/26/21153579/disney-ceo-bob-iger-chapek-mayer-streaming-succession-tim-cook-steve-jobs">had been called the “Tim Cook to Iger’s Steve Jobs,”</a> but during his tenure, their handover got off to a rocky start, while blowups like the
    //                 <a href="https://www.theverge.com/2021/7/29/22600396/scarlett-johansson-suing-disney-black-widow-release">Scarlett Johansson
    //                     <em>Black Widow</em> lawsuit
    //                 </a> and Disney’s initial lack of reaction to the “Don’t Say Gay” bill in Florida scuffed its all-important reputation.
    //             </p>
    //             <div class="c-float-left c-float-hang">
    //                 <div id="KHz6gw"></div>
    //             </div>
    //             <p id="2JSx2D">During
    //                 <a href="https://www.theverge.com/23010559/decoder-streaming-platforms-cable-netflix-disney-apple">an episode of the
    //                     <em>Decoder </em>podcast...
    //                 </a>
    //             </p>
    //             <p>
    //                 <a href="https://www.theverge.com/2022/11/20/23470368/disney-ceo-bob-iger-in-bob-chapek-out">Continue reading&hellip;</a>
    //             </p>
    //         </content>
    //         <link rel="alternate" type="text/html" href="https://www.theverge.com/2022/11/20/23470368/disney-ceo-bob-iger-in-bob-chapek-out"/>
    //         <id>https://www.theverge.com/2022/11/20/23470368/disney-ceo-bob-iger-in-bob-chapek-out</id>
    //         <author>
    //             <name>Richard Lawler</name>
    //         </author>
    //     </entry>
    //     <entry>
    //         <published>2022-11-21T17:51:41-05:00</published>
    //         <updated>2022-11-21T17:51:41-05:00</updated>
    //         <title>The best Black Friday deals you can already get at Amazon</title>
    //         <content type="html">
    //             <figure>
    //                 <img alt="Google’s Pixel Buds Pro earbuds, in yellow lemongrass color, resting at the foot of their white charging case on a tabletop." src="https://cdn.vox-cdn.com/thumbor/iYwRuqLOBOqomCH1lG0lDWFheGA=/0x0:2040x1360/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659281/DSCF8502.0.jpg" />
    //                 <figcaption>
    //                     <em>Amazon’s Black Friday discounts extend to more than just Amazon devices.</em> | Photo by Chris Welch / The Verge
    //                 </figcaption>
    //             </figure>
    //             <p id="aRKQfH">Black Friday is right around the corner, but Amazon is wasting no time by rolling out some excellent deals in the run-up to the main event on Friday. If you’re looking to knock out some of your holiday shopping early, we’ve rounded up a small collection of all the best discounts you can currently get on wireless headphones, 4K TVs, tablets, and more. </p>
    //             <div class="c-float-left c-float-hang">
    //                 <aside id="ABSC8o">
    //                     <div data-anthem-component="readmore" data-anthem-component-data='{"stories":[{"title":"The Verge Holiday Gift Guide 2022","url":"https://www.theverge.com/23435489/holiday-gift-guide-best-ideas-cool-tech"},{"title":"The best early Black Friday deals you can already get","url":"https://www.theverge.com/23438688/black-friday-2022-best-early-deals-tech-tv-apple-smart-home"},{"title":"Know the price-matching policies for Best Buy, Target, Walmart, and others","url":"https://www.theverge.com/21570383/price-matching-policy-apple-google-microsoft"}]}'></div>
    //                 </aside>
    //             </div>
    //             <p id="HtHGHM">If you’re looking for discounts at other retailers, we’ve also put together roundups of the best deals you can find ahead of Black Friday at
    //                 <a href="https://www.theverge.com/e/23197114">Target</a>,
    //                 <a href="https://www.theverge.com/e/23160805">Best Buy</a>, and
    //                 <a href="https://www.theverge.com/e/23204521">Walmart</a>. To stay up to speed with everything happening over Black Friday and Cyber Monday, make sure to bookmark our
    //                 <a href="https://www.theverge.com/e/23197880">Black Friday hub</a> and check back for regular updates.
    //             </p>
    //             <div id="hjLr4p">
    //                 <link rel="stylesheet" href="https://s3.amazonaws.com/assets.sbnation.com/csk/uploads/verge-toc.css">
    //                     <div class="duet--article--article-body-component verge-table-of-contents border-franklin border" id="toc-main"></div>
    //                 </div>
    //                 <hr class="p-entry-hr" id="MUyQMv">
    //                     <h2 id="oQgeHw">The best Amazon Black Friday deals on Echo...</h2>
    //                     <p>
    //                         <a href="https://www.theverge.com/23466456/amazon-black-friday-2022-deals-cyber-monday-tech-games-tv">Continue reading&hellip;</a>
    //                     </p>
    //                 </content>
    //                 <link rel="alternate" type="text/html" href="https://www.theverge.com/23466456/amazon-black-friday-2022-deals-cyber-monday-tech-games-tv"/>
    //                 <id>https://www.theverge.com/23466456/amazon-black-friday-2022-deals-cyber-monday-tech-games-tv</id>
    //                 <author>
    //                     <name>Alice Newcome-Beill</name>
    //                 </author>
    //             </entry>
    //         </feed>
};
