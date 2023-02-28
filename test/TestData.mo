import Types "../src/Types";
import Tokenizer "../src/Tokenizer";
import Parser "../src/Parser";

module {

    public type Example = {
        name : Text;
        raw : Text;
        tokens : [Types.Token];
        doc : Types.Document;
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
                #text("<>&'\"{🤣"),
                #endTag({ name = "root" }),
            ];
            doc = {
                encoding = null;
                processInstructions = [];
                root = {
                    attributes = [];
                    children = #open([#text("<>&'\"{🤣")]);
                    name = "root";
                };
                standalone = null;
                version = null;
                docType = null;
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
                #text("You will see this in the document and can use reserved characters like < > & \""),
                #endTag({ name = "root" }),
            ];
            doc = {
                encoding = null;
                processInstructions = [];
                root = {
                    attributes = [];
                    children = #open([#text("You will see this in the document and can use reserved characters like < > & \"")]);
                    name = "root";
                };
                standalone = null;
                version = null;
                docType = null;
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
        },
        {
            name = "XML Declaration";
            raw = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><top a=b c=\"d\"><!-- comment --><mid t=5/><bottom >Content</ bottom></top>";
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
        },
        {
            name = "DOCTYPE";
            raw = "<!DOCTYPE root [ <!ELEMENT foo (#PCDATA)> <!ELEMENT img EMPTY> <!ELEMENT img2 ANY> <!ELEMENT img3 (foo)> <!ELEMENT img4 (foo|img)> <!ELEMENT img5 (foo,img)> <!ELEMENT img3 (foo*)> <!ELEMENT img3 (foo+)> <!ELEMENT img3 (foo?)> <!ELEMENT img3 ((foo|img)*)>]><root></root>";
            tokens = [
                #docType({
                    rootElementName = "root";
                    typeDefinition = {
                        externalTypes = null;
                        internalTypes = [];
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
                encoding = null;
                processInstructions = [];
                root = {
                    attributes = [];
                    children = #open([]);
                    name = "root";
                };
                standalone = null;
                version = null;
                docType = ?{
                    rootElementName = "root";
                    typeDefinition = {
                        externalTypes = null;
                        internalTypes = [];
                    };
                };
            };
        },
        {
            name = "RSS Feed";
            raw : Text = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><feed xmlns=\"http://www.w3.org/2005/Atom\" xml:lang=\"en\"><title>The Verge - All Posts</title><icon>https://cdn.vox-cdn.com/community_logos/52801/VER_Logomark_32x32..png</icon><updated>2022-11-21T21:30:42-05:00</updated><id>https://www.theverge.com/rss/full.xml</id><link type=\"text/html\" href=\"https://www.theverge.com/\" rel=\"alternate\"/><entry><published>2022-11-21T21:30:42-05:00</published><updated>2022-11-21T21:30:42-05:00</updated><title>Twitter is making DMs encrypted and adding video, voice chat, per Elon Musk</title><content type=\"html\"><figure><img alt=\"An illustration of the Twitter logo\" src=\"https://cdn.vox-cdn.com/thumbor/6kBqimyOvt-iCvNDVhv2okF4ey4=/0x0:3000x2000/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659917/acastro_STK050_04.0.jpg\" /><figcaption>Illustration by Alex Castro / The Verge</figcaption></figure><p id=\"TvAhZo\">Twitter’s new owner, Elon Musk, has been public about his desire to improve how the social network’s direct messages work. In a meeting with employees today, he spelled out exactly what that looks like.</p><p id=\"6MmlUD\">Framed by presentation slides titled “Twitter 2.0” at Twitter’s San Fransisco headquarters on Monday, Musk told employees that the company would encrypt DMs and work to add encrypted video and voice calling between accounts, according to a recording of the meeting obtained by<em>The Verge</em>.</p><p id=\"Z8NlgY\">“We want to enable users to be able to communicate without being concerned about their privacy, [or] without being concerned about a data breach at Twitter causing all of their DMs to hit the web, or think that maybe someone at Twitter could be spying on...</p><p><a href=\"https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling\">Continue reading&hellip;</a></p></content><link rel=\"alternate\" type=\"text/html\" href=\"https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling\"/><id>https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling</id><author><name>Alex Heath</name></author></entry><entry><published>2022-11-21T20:24:25-05:00</published><updated>2022-11-21T20:24:25-05:00</updated><title>Domino’s is building an all-electric pizza delivery fleet with Chevy Bolts</title><content type=\"html\"><figure><img alt=\"Two chevy bolt ev cars, wrapped in domino’s artwork are parked in front of a domino’s pizza store with one of the cars hooked up to a charger.\" src=\"https://cdn.vox-cdn.com/thumbor/uraUyO3VeLJ8RJ6ethB54sPF1bs=/0x1:2048x1366/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659802/Dominos_Chevy_Bolt_EVs_08.0.jpg\" /><figcaption><em>Domino’s outfitted Chevy Bolts.</em> | Image: Domino’s</figcaption></figure><p id=\"1PMpbG\">Domino’s is gearing up to put<a href=\"https://ir.dominos.com/news-releases/news-release-details/dominosr-roll-out-nationwide-fleet-800-chevy-boltr-electric\">more than 800 all-electric pizza delivery vehicles into service</a> in the coming months, starting with over 100 of them rolling out in November. The company went with the compact Chevy Bolt EV and is wrapping the vehicles with custom branding but no other bells and whistles — just combustion-free deliveries (via<a href=\"https://electrek.co/2022/11/21/dominos-acquires-800-chevy-bolts-evs-for-delivery-fleet/\"><em>electrek</em></a>).</p><p id=\"Lo1Jmp\">Domino will have a fleet of 855 new electric vehicles, to be exact, and while that’s not quite enough to reach<a href=\"https://ir.dominos.com/static-files/4daec873-268e-4456-b541-3871f28288e2\">all 6,135 of the pizza shops in the US</a>, it's more than the Chevy Spark-based (gas version) ones it built with<a href=\"https://www.theverge.com/2015/10/21/9587270/dominos-dxp-delivery-car-chevy-spark-pizza\">custom pizza warming oven doors</a> in 2015. Those were called the Domino’s DXP, and only 155 of them were made. For the new Bolts, drivers will need to toss the HeatWave bags in...</p><p><a href=\"https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout\">Continue reading&hellip;</a></p></content><link rel=\"alternate\" type=\"text/html\" href=\"https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout\"/><id>https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout</id><author><name>Umar Shakir</name></author></entry><entry><published>2022-11-21T19:44:46-05:00</published><updated>2022-11-21T19:44:46-05:00</updated><title>Elon Musk bought Twitter, and here’s everything that happened next</title><content type=\"html\"><figure><img alt=\"\" src=\"https://cdn.vox-cdn.com/thumbor/gOLos_N33sgfTa2gWSVdcAxcqt0=/0x0:2040x1360/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/70735423/STK171_VRG_Illo_5_Normand_ElonMusk_05.5.jpg\" /><figcaption>Laura Normand / The Verge</figcaption></figure><p>Elon Musk is now the owner, CEO, and sole director of Twitter. His “Twitter 2.0” era has so far included mass layoffs and rapidly changing policy decisions.</p><p><a href=\"https://www.theverge.com/2022/4/11/23019836/elon-musk-twitter-board-of-directors-news-updates\">Continue reading&hellip;</a></p></content><link rel=\"alternate\" type=\"text/html\" href=\"https://www.theverge.com/2022/4/11/23019836/elon-musk-twitter-board-of-directors-news-updates\"/><id>https://www.theverge.com/2022/4/11/23019836/elon-musk-twitter-board-of-directors-news-updates</id><author><name>Alex Heath</name><name>Emma Roth</name><name>James Vincent</name><name>Sean Hollister</name><name>Nilay Patel</name><name>Mitchell Clark</name><name>Richard Lawler</name><name>Russell Brandom</name><name>Elizabeth Lopatto</name><name>Thomas Ricker</name><name>Mia Sato</name></author></entry><entry><published>2022-11-21T19:31:11-05:00</published><updated>2022-11-21T19:31:11-05:00</updated><title>Twitter won’t restart paid verification until ‘significant impersonations’ stop, Elon Musk says</title><content type=\"html\"><figure><img alt=\"An illustration of the Twitter logo.\" src=\"https://cdn.vox-cdn.com/thumbor/zQLVeU7EwVTBQLHivgfUFyqWqvM=/0x0:3000x2000/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659669/acastro_STK050_06.5.jpg\" /><figcaption>Illustration by Alex Castro / The Verge</figcaption></figure><p id=\"InvXEX\">Elon Musk told Twitter employees on Monday that the company won’t relaunch its paid verification subscription, Twitter Blue, until “we’re confident about significant impersonations not happening,” according to a recording of his remarks obtained by<em>The Verge</em>.</p><p id=\"iN7NAx\">Musk said last week that his $8 per month Blue subscription<a href=\"https://www.theverge.com/2022/11/15/23461244/twitter-blue-relaunch-verification-elon-musk\">would be made available again on November 29th</a>. But in the meeting with employees, he said the timing of the launch was unclear: “We might launch it next week. We might not. But we’re not going to launch until there’s high confidence in protecting against those significant impersonations.”</p><p id=\"Le0vLW\">After taking over Twitter, Musk’s first big change was to quickly introduce the ability for users to buy a blue checkmark through...</p><p><a href=\"https://www.theverge.com/2022/11/21/23472184/elon-musk-twitter-paid-verification-relaunch-delay-impersonations\">Continue reading&hellip;</a></p></content><link rel=\"alternate\" type=\"text/html\" href=\"https://www.theverge.com/2022/11/21/23472184/elon-musk-twitter-paid-verification-relaunch-delay-impersonations\"/><id>https://www.theverge.com/2022/11/21/23472184/elon-musk-twitter-paid-verification-relaunch-delay-impersonations</id><author><name>Alex Heath</name></author></entry><entry><published>2022-11-21T19:00:00-05:00</published><updated>2022-11-21T19:00:00-05:00</updated><title>Apple changed how reading books works in iOS 16, and I may never be happy again</title><content type=\"html\"><figure><img alt=\"Nilay Patel holds an iPhone 14 Pro in his hands.\" src=\"https://cdn.vox-cdn.com/thumbor/fy-1OSl08rP0neOAsPVBx3gB7kM=/0x0:2040x1360/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659548/226270_iPHONE_14_PHO_akrales_0030.0.jpg\" /><figcaption><em>Am I being dramatic? Yes. Has this change made me read on my phone less? Also yes.</em> | Photo by Amelia Holowaty Krales / The Verge</figcaption></figure><p id=\"NwS67V\">Apple Books has been my main reading app for years for one very specific reason: its page-turning animation is far and away the best in the business. Unfortunately, that went away with iOS 16 and has been replaced by a new animation that makes it feel like you’re moving cards through a deck instead of leafing through a digitized version of paper. And despite the fact that I’ve been trying to get used to the change since I got onto the beta in July, I still feel like Apple’s destroyed one of the last ways that my phone brought joy into my life.</p><p id=\"ed6BLz\">For those unfamiliar with Apple’s Books app (formerly known as iBooks), I’ll try to explain the hole that’s suddenly been punched into my reading life. Before iOS 16, the app would play a...</p><p><a href=\"https://www.theverge.com/2022/11/21/23471306/apple-books-ios-16-page-flip-animation-sucks\">Continue reading&hellip;</a></p></content><link rel=\"alternate\" type=\"text/html\" href=\"https://www.theverge.com/2022/11/21/23471306/apple-books-ios-16-page-flip-animation-sucks\"/><id>https://www.theverge.com/2022/11/21/23471306/apple-books-ios-16-page-flip-animation-sucks</id><author><name>Mitchell Clark</name></author></entry><entry><published>2022-11-21T18:46:49-05:00</published><updated>2022-11-21T18:46:49-05:00</updated><title>iOS developers say Apple’s App Store analytics aren’t anonymous</title><content type=\"html\"><figure><img alt=\"\" src=\"https://cdn.vox-cdn.com/thumbor/eYqZ0c_m283srxzRlmzfjkoh_pQ=/119x0:1952x1222/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659501/Screenshot_2022_11_21_at_14.03.07.0.png\" /><figcaption>Image: Apple</figcaption></figure><p id=\"xinbTn\">The detailed analytics data Apple records about what you do in the App Store can be tied directly to your Apple account, according to app development and research team Mysk. In<a href=\"https://twitter.com/mysk_co/status/1594515229915979776\">a Twitter thread</a>, Mysk shows that Apple sends what’s known as a “Directory Services Identifier” along with its App Store analytics info and argues that the identifier is also tied to your iCloud account, linking your name, email address, and more.</p><p id=\"zrD2cY\">The thread also notes that the data is still sent even if you turn off device analytics in settings, and that Apple sends your DSID in other apps as well. In the last tweet in the thread, Mysk says: “You just need to know three things: 1- The App Store sends detailed analytics about you to Apple. 2- There’s no way to...</p><p><a href=\"https://www.theverge.com/2022/11/21/23471827/apple-app-store-data-collection-analytics-personal-info-privacy\">Continue reading&hellip;</a></p></content><link rel=\"alternate\" type=\"text/html\" href=\"https://www.theverge.com/2022/11/21/23471827/apple-app-store-data-collection-analytics-personal-info-privacy\"/><id>https://www.theverge.com/2022/11/21/23471827/apple-app-store-data-collection-analytics-personal-info-privacy</id><author><name>Mitchell Clark</name></author></entry><entry><published>2022-11-21T18:03:32-05:00</published><updated>2022-11-21T18:03:32-05:00</updated><title>Bob Iger steps back in as Disney CEO, replacing Bob Chapek </title><content type=\"html\"><figure><img alt=\"A colorful graphical illustration of the Disney Plus logo.\" src=\"https://cdn.vox-cdn.com/thumbor/LBZpzWdUUjxgvybEwhbunWt_HHw=/0x0:2040x1360/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71655348/acastro_STK080_disneyPlus_02.0.jpg\" /><figcaption>Illustration by Alex Castro / The Verge</figcaption></figure><p id=\"SOoXw3\">In a sudden turn of events, Disney has reversed<a href=\"https://www.theverge.com/2020/2/25/21153317/bob-iger-disney-ceo-steps-down-chapek-kevin-mayer-parks-products-succession\">the CEO swap that surprised us in early 2020</a>, with Bob Iger<a href=\"https://thewaltdisneycompany.com/the-walt-disney-company-board-of-directors-appoints-robert-a-iger-as-chief-executive-officer/\">returning to his post</a>, replacing his own successor, Bob Chapek. Iger, who is also the company’s largest shareholder, is now set to serve a new two-year term as CEO. Part of Iger’s job in those two years will be to pick and groom his long-term successor.</p><p id=\"v6tlhA\">Of course, Chapek was an Iger choice too. Chapek<a href=\"https://www.theverge.com/2020/2/26/21153579/disney-ceo-bob-iger-chapek-mayer-streaming-succession-tim-cook-steve-jobs\">had been called the “Tim Cook to Iger’s Steve Jobs,”</a> but during his tenure, their handover got off to a rocky start, while blowups like the<a href=\"https://www.theverge.com/2021/7/29/22600396/scarlett-johansson-suing-disney-black-widow-release\">Scarlett Johansson<em>Black Widow</em> lawsuit</a> and Disney’s initial lack of reaction to the “Don’t Say Gay” bill in Florida scuffed its all-important reputation.</p><div class=\"c-float-left c-float-hang\"><div id=\"KHz6gw\"></div></div><p id=\"2JSx2D\">During<a href=\"https://www.theverge.com/23010559/decoder-streaming-platforms-cable-netflix-disney-apple\">an episode of the<em>Decoder </em>podcast...</a></p><p><a href=\"https://www.theverge.com/2022/11/20/23470368/disney-ceo-bob-iger-in-bob-chapek-out\">Continue reading&hellip;</a></p></content><link rel=\"alternate\" type=\"text/html\" href=\"https://www.theverge.com/2022/11/20/23470368/disney-ceo-bob-iger-in-bob-chapek-out\"/><id>https://www.theverge.com/2022/11/20/23470368/disney-ceo-bob-iger-in-bob-chapek-out</id><author><name>Richard Lawler</name></author></entry><entry><published>2022-11-21T17:51:41-05:00</published><updated>2022-11-21T17:51:41-05:00</updated><title>The best Black Friday deals you can already get at Amazon</title><content type=\"html\"><figure><img alt=\"Google’s Pixel Buds Pro earbuds, in yellow lemongrass color, resting at the foot of their white charging case on a tabletop.\" src=\"https://cdn.vox-cdn.com/thumbor/iYwRuqLOBOqomCH1lG0lDWFheGA=/0x0:2040x1360/1310x873/cdn.vox-cdn.com/uploads/chorus_image/image/71659281/DSCF8502.0.jpg\" /><figcaption><em>Amazon’s Black Friday discounts extend to more than just Amazon devices.</em> | Photo by Chris Welch / The Verge</figcaption></figure><p id=\"aRKQfH\">Black Friday is right around the corner, but Amazon is wasting no time by rolling out some excellent deals in the run-up to the main event on Friday. If you’re looking to knock out some of your holiday shopping early, we’ve rounded up a small collection of all the best discounts you can currently get on wireless headphones, 4K TVs, tablets, and more. </p><div class=\"c-float-left c-float-hang\"><aside id=\"ABSC8o\"><div data-anthem-component=\"readmore\" data-anthem-component-data='{\"stories\":[{\"title\":\"The Verge Holiday Gift Guide 2022\",\"url\":\"https://www.theverge.com/23435489/holiday-gift-guide-best-ideas-cool-tech\"},{\"title\":\"The best early Black Friday deals you can already get\",\"url\":\"https://www.theverge.com/23438688/black-friday-2022-best-early-deals-tech-tv-apple-smart-home\"},{\"title\":\"Know the price-matching policies for Best Buy, Target, Walmart, and others\",\"url\":\"https://www.theverge.com/21570383/price-matching-policy-apple-google-microsoft\"}]}'></div></aside></div><p id=\"HtHGHM\">If you’re looking for discounts at other retailers, we’ve also put together roundups of the best deals you can find ahead of Black Friday at<a href=\"https://www.theverge.com/e/23197114\">Target</a>,<a href=\"https://www.theverge.com/e/23160805\">Best Buy</a>, and<a href=\"https://www.theverge.com/e/23204521\">Walmart</a>. To stay up to speed with everything happening over Black Friday and Cyber Monday, make sure to bookmark our<a href=\"https://www.theverge.com/e/23197880\">Black Friday hub</a> and check back for regular updates.</p><div id=\"hjLr4p\"><link rel=\"stylesheet\" href=\"https://s3.amazonaws.com/assets.sbnation.com/csk/uploads/verge-toc.css\"/><div class=\"duet--article--article-body-component verge-table-of-contents border-franklin border\" id=\"toc-main\"></div></div><hr class=\"p-entry-hr\" id=\"MUyQMv\"/><h2 id=\"oQgeHw\">The best Amazon Black Friday deals on Echo...</h2><p><a href=\"https://www.theverge.com/23466456/amazon-black-friday-2022-deals-cyber-monday-tech-games-tv\">Continue reading&hellip;</a></p></content><link rel=\"alternate\" type=\"text/html\" href=\"https://www.theverge.com/23466456/amazon-black-friday-2022-deals-cyber-monday-tech-games-tv\"/><id>https://www.theverge.com/23466456/amazon-black-friday-2022-deals-cyber-monday-tech-games-tv</id><author><name>Alice Newcome-Beill</name></author></entry></feed>";
            tokens : [Types.Token] = [
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
                    attributes = [{ name = "alt"; value = ?"An illustration of the Twitter logo" }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/6kBqimyOvt-iCvNDVhv2okF4ey4" }];
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
                    attributes = [{ name = "alt"; value = ?"Two chevy bolt ev cars, wrapped in domino’s artwork are parked in front of a domino’s pizza store with one of the cars hooked up to a charger." }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/uraUyO3VeLJ8RJ6ethB54sPF1bs" }];
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
                #text("2022-11-21T19:44:46-05:00"),
                #endTag({ name = "published" }),
                #startTag({
                    attributes = [];
                    name = "updated";
                    selfClosing = false;
                }),
                #text("2022-11-21T19:44:46-05:00"),
                #endTag({ name = "updated" }),
                #startTag({
                    attributes = [];
                    name = "title";
                    selfClosing = false;
                }),
                #text("Elon Musk bought Twitter, and here’s everything that happened next"),
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
                    attributes = [{ name = "alt"; value = ?"" }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/gOLos_N33sgfTa2gWSVdcAxcqt0" }];
                    name = "img";
                    selfClosing = true;
                }),
                #startTag({
                    attributes = [];
                    name = "figcaption";
                    selfClosing = false;
                }),
                #text("Laura Normand / The Verge"),
                #endTag({ name = "figcaption" }),
                #endTag({ name = "figure" }),
                #startTag({
                    attributes = [];
                    name = "p";
                    selfClosing = false;
                }),
                #text("Elon Musk is now the owner, CEO, and sole director of Twitter. His “Twitter 2.0” era has so far included mass layoffs and rapidly changing policy decisions."),
                #endTag({ name = "p" }),
                #startTag({
                    attributes = [];
                    name = "p";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/2022/4/11/23019836/elon-musk-twitter-board-of-directors-news-updates";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("Continue reading&hellip;"),
                #endTag({ name = "a" }),
                #endTag({ name = "p" }),
                #endTag({ name = "content" }),
                #startTag({
                    attributes = [{ name = "rel"; value = ?"alternate" }, { name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/2022/4/11/23019836/elon-musk-twitter-board-of-directors-news-updates" }];
                    name = "link";
                    selfClosing = true;
                }),
                #startTag({
                    attributes = [];
                    name = "id";
                    selfClosing = false;
                }),
                #text("https://www.theverge.com/2022/4/11/23019836/elon-musk-twitter-board-of-directors-news-updates"),
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
                #startTag({
                    attributes = [];
                    name = "name";
                    selfClosing = false;
                }),
                #text("Emma Roth"),
                #endTag({ name = "name" }),
                #startTag({
                    attributes = [];
                    name = "name";
                    selfClosing = false;
                }),
                #text("James Vincent"),
                #endTag({ name = "name" }),
                #startTag({
                    attributes = [];
                    name = "name";
                    selfClosing = false;
                }),
                #text("Sean Hollister"),
                #endTag({ name = "name" }),
                #startTag({
                    attributes = [];
                    name = "name";
                    selfClosing = false;
                }),
                #text("Nilay Patel"),
                #endTag({ name = "name" }),
                #startTag({
                    attributes = [];
                    name = "name";
                    selfClosing = false;
                }),
                #text("Mitchell Clark"),
                #endTag({ name = "name" }),
                #startTag({
                    attributes = [];
                    name = "name";
                    selfClosing = false;
                }),
                #text("Richard Lawler"),
                #endTag({ name = "name" }),
                #startTag({
                    attributes = [];
                    name = "name";
                    selfClosing = false;
                }),
                #text("Russell Brandom"),
                #endTag({ name = "name" }),
                #startTag({
                    attributes = [];
                    name = "name";
                    selfClosing = false;
                }),
                #text("Elizabeth Lopatto"),
                #endTag({ name = "name" }),
                #startTag({
                    attributes = [];
                    name = "name";
                    selfClosing = false;
                }),
                #text("Thomas Ricker"),
                #endTag({ name = "name" }),
                #startTag({
                    attributes = [];
                    name = "name";
                    selfClosing = false;
                }),
                #text("Mia Sato"),
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
                #text("2022-11-21T19:31:11-05:00"),
                #endTag({ name = "published" }),
                #startTag({
                    attributes = [];
                    name = "updated";
                    selfClosing = false;
                }),
                #text("2022-11-21T19:31:11-05:00"),
                #endTag({ name = "updated" }),
                #startTag({
                    attributes = [];
                    name = "title";
                    selfClosing = false;
                }),
                #text("Twitter won’t restart paid verification until ‘significant impersonations’ stop, Elon Musk says"),
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
                    attributes = [{ name = "alt"; value = ?"An illustration of the Twitter logo." }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/zQLVeU7EwVTBQLHivgfUFyqWqvM" }];
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
                    attributes = [{ name = "id"; value = ?"InvXEX" }];
                    name = "p";
                    selfClosing = false;
                }),
                #text("Elon Musk told Twitter employees on Monday that the company won’t relaunch its paid verification subscription, Twitter Blue, until “we’re confident about significant impersonations not happening,” according to a recording of his remarks obtained by"),
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
                    attributes = [{ name = "id"; value = ?"iN7NAx" }];
                    name = "p";
                    selfClosing = false;
                }),
                #text("Musk said last week that his $8 per month Blue subscription"),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/2022/11/15/23461244/twitter-blue-relaunch-verification-elon-musk";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("would be made available again on November 29th"),
                #endTag({ name = "a" }),
                #text(". But in the meeting with employees, he said the timing of the launch was unclear: “We might launch it next week. We might not. But we’re not going to launch until there’s high confidence in protecting against those significant impersonations.”"),
                #endTag({ name = "p" }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"Le0vLW" }];
                    name = "p";
                    selfClosing = false;
                }),
                #text("After taking over Twitter, Musk’s first big change was to quickly introduce the ability for users to buy a blue checkmark through..."),
                #endTag({ name = "p" }),
                #startTag({
                    attributes = [];
                    name = "p";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/2022/11/21/23472184/elon-musk-twitter-paid-verification-relaunch-delay-impersonations";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("Continue reading&hellip;"),
                #endTag({ name = "a" }),
                #endTag({ name = "p" }),
                #endTag({ name = "content" }),
                #startTag({
                    attributes = [{ name = "rel"; value = ?"alternate" }, { name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/2022/11/21/23472184/elon-musk-twitter-paid-verification-relaunch-delay-impersonations" }];
                    name = "link";
                    selfClosing = true;
                }),
                #startTag({
                    attributes = [];
                    name = "id";
                    selfClosing = false;
                }),
                #text("https://www.theverge.com/2022/11/21/23472184/elon-musk-twitter-paid-verification-relaunch-delay-impersonations"),
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
                #text("2022-11-21T19:00:00-05:00"),
                #endTag({ name = "published" }),
                #startTag({
                    attributes = [];
                    name = "updated";
                    selfClosing = false;
                }),
                #text("2022-11-21T19:00:00-05:00"),
                #endTag({ name = "updated" }),
                #startTag({
                    attributes = [];
                    name = "title";
                    selfClosing = false;
                }),
                #text("Apple changed how reading books works in iOS 16, and I may never be happy again"),
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
                    attributes = [{ name = "alt"; value = ?"Nilay Patel holds an iPhone 14 Pro in his hands." }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/fy-1OSl08rP0neOAsPVBx3gB7kM" }];
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
                #text("Am I being dramatic? Yes. Has this change made me read on my phone less? Also yes."),
                #endTag({ name = "em" }),
                #text("| Photo by Amelia Holowaty Krales / The Verge"),
                #endTag({ name = "figcaption" }),
                #endTag({ name = "figure" }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"NwS67V" }];
                    name = "p";
                    selfClosing = false;
                }),
                #text("Apple Books has been my main reading app for years for one very specific reason: its page-turning animation is far and away the best in the business. Unfortunately, that went away with iOS 16 and has been replaced by a new animation that makes it feel like you’re moving cards through a deck instead of leafing through a digitized version of paper. And despite the fact that I’ve been trying to get used to the change since I got onto the beta in July, I still feel like Apple’s destroyed one of the last ways that my phone brought joy into my life."),
                #endTag({ name = "p" }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"ed6BLz" }];
                    name = "p";
                    selfClosing = false;
                }),
                #text("For those unfamiliar with Apple’s Books app (formerly known as iBooks), I’ll try to explain the hole that’s suddenly been punched into my reading life. Before iOS 16, the app would play a..."),
                #endTag({ name = "p" }),
                #startTag({
                    attributes = [];
                    name = "p";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/2022/11/21/23471306/apple-books-ios-16-page-flip-animation-sucks";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("Continue reading&hellip;"),
                #endTag({ name = "a" }),
                #endTag({ name = "p" }),
                #endTag({ name = "content" }),
                #startTag({
                    attributes = [{ name = "rel"; value = ?"alternate" }, { name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/2022/11/21/23471306/apple-books-ios-16-page-flip-animation-sucks" }];
                    name = "link";
                    selfClosing = true;
                }),
                #startTag({
                    attributes = [];
                    name = "id";
                    selfClosing = false;
                }),
                #text("https://www.theverge.com/2022/11/21/23471306/apple-books-ios-16-page-flip-animation-sucks"),
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
                #text("Mitchell Clark"),
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
                #text("2022-11-21T18:46:49-05:00"),
                #endTag({ name = "published" }),
                #startTag({
                    attributes = [];
                    name = "updated";
                    selfClosing = false;
                }),
                #text("2022-11-21T18:46:49-05:00"),
                #endTag({ name = "updated" }),
                #startTag({
                    attributes = [];
                    name = "title";
                    selfClosing = false;
                }),
                #text("iOS developers say Apple’s App Store analytics aren’t anonymous"),
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
                    attributes = [{ name = "alt"; value = ?"" }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/eYqZ0c_m283srxzRlmzfjkoh_pQ" }];
                    name = "img";
                    selfClosing = true;
                }),
                #startTag({
                    attributes = [];
                    name = "figcaption";
                    selfClosing = false;
                }),
                #text("Image: Apple"),
                #endTag({ name = "figcaption" }),
                #endTag({ name = "figure" }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"xinbTn" }];
                    name = "p";
                    selfClosing = false;
                }),
                #text("The detailed analytics data Apple records about what you do in the App Store can be tied directly to your Apple account, according to app development and research team Mysk. In"),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://twitter.com/mysk_co/status/1594515229915979776";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("a Twitter thread"),
                #endTag({ name = "a" }),
                #text(", Mysk shows that Apple sends what’s known as a “Directory Services Identifier” along with its App Store analytics info and argues that the identifier is also tied to your iCloud account, linking your name, email address, and more."),
                #endTag({ name = "p" }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"zrD2cY" }];
                    name = "p";
                    selfClosing = false;
                }),
                #text("The thread also notes that the data is still sent even if you turn off device analytics in settings, and that Apple sends your DSID in other apps as well. In the last tweet in the thread, Mysk says: “You just need to know three things: 1- The App Store sends detailed analytics about you to Apple. 2- There’s no way to..."),
                #endTag({ name = "p" }),
                #startTag({
                    attributes = [];
                    name = "p";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/2022/11/21/23471827/apple-app-store-data-collection-analytics-personal-info-privacy";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("Continue reading&hellip;"),
                #endTag({ name = "a" }),
                #endTag({ name = "p" }),
                #endTag({ name = "content" }),
                #startTag({
                    attributes = [{ name = "rel"; value = ?"alternate" }, { name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/2022/11/21/23471827/apple-app-store-data-collection-analytics-personal-info-privacy" }];
                    name = "link";
                    selfClosing = true;
                }),
                #startTag({
                    attributes = [];
                    name = "id";
                    selfClosing = false;
                }),
                #text("https://www.theverge.com/2022/11/21/23471827/apple-app-store-data-collection-analytics-personal-info-privacy"),
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
                #text("Mitchell Clark"),
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
                #text("2022-11-21T18:03:32-05:00"),
                #endTag({ name = "published" }),
                #startTag({
                    attributes = [];
                    name = "updated";
                    selfClosing = false;
                }),
                #text("2022-11-21T18:03:32-05:00"),
                #endTag({ name = "updated" }),
                #startTag({
                    attributes = [];
                    name = "title";
                    selfClosing = false;
                }),
                #text("Bob Iger steps back in as Disney CEO, replacing Bob Chapek "),
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
                    attributes = [{ name = "alt"; value = ?"A colorful graphical illustration of the Disney Plus logo." }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/LBZpzWdUUjxgvybEwhbunWt_HHw" }];
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
                    attributes = [{ name = "id"; value = ?"SOoXw3" }];
                    name = "p";
                    selfClosing = false;
                }),
                #text("In a sudden turn of events, Disney has reversed"),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/2020/2/25/21153317/bob-iger-disney-ceo-steps-down-chapek-kevin-mayer-parks-products-succession";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("the CEO swap that surprised us in early 2020"),
                #endTag({ name = "a" }),
                #text(", with Bob Iger"),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://thewaltdisneycompany.com/the-walt-disney-company-board-of-directors-appoints-robert-a-iger-as-chief-executive-officer/";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("returning to his post"),
                #endTag({ name = "a" }),
                #text(", replacing his own successor, Bob Chapek. Iger, who is also the company’s largest shareholder, is now set to serve a new two-year term as CEO. Part of Iger’s job in those two years will be to pick and groom his long-term successor."),
                #endTag({ name = "p" }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"v6tlhA" }];
                    name = "p";
                    selfClosing = false;
                }),
                #text("Of course, Chapek was an Iger choice too. Chapek"),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/2020/2/26/21153579/disney-ceo-bob-iger-chapek-mayer-streaming-succession-tim-cook-steve-jobs";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("had been called the “Tim Cook to Iger’s Steve Jobs,”"),
                #endTag({ name = "a" }),
                #text("but during his tenure, their handover got off to a rocky start, while blowups like the"),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/2021/7/29/22600396/scarlett-johansson-suing-disney-black-widow-release";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("Scarlett Johansson"),
                #startTag({
                    attributes = [];
                    name = "em";
                    selfClosing = false;
                }),
                #text("Black Widow"),
                #endTag({ name = "em" }),
                #text("lawsuit"),
                #endTag({ name = "a" }),
                #text("and Disney’s initial lack of reaction to the “Don’t Say Gay” bill in Florida scuffed its all-important reputation."),
                #endTag({ name = "p" }),
                #startTag({
                    attributes = [{
                        name = "class";
                        value = ?"c-float-left c-float-hang";
                    }];
                    name = "div";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"KHz6gw" }];
                    name = "div";
                    selfClosing = false;
                }),
                #endTag({ name = "div" }),
                #endTag({ name = "div" }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"2JSx2D" }];
                    name = "p";
                    selfClosing = false;
                }),
                #text("During"),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/23010559/decoder-streaming-platforms-cable-netflix-disney-apple";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("an episode of the"),
                #startTag({
                    attributes = [];
                    name = "em";
                    selfClosing = false;
                }),
                #text("Decoder "),
                #endTag({ name = "em" }),
                #text("podcast..."),
                #endTag({ name = "a" }),
                #endTag({ name = "p" }),
                #startTag({
                    attributes = [];
                    name = "p";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/2022/11/20/23470368/disney-ceo-bob-iger-in-bob-chapek-out";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("Continue reading&hellip;"),
                #endTag({ name = "a" }),
                #endTag({ name = "p" }),
                #endTag({ name = "content" }),
                #startTag({
                    attributes = [{ name = "rel"; value = ?"alternate" }, { name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/2022/11/20/23470368/disney-ceo-bob-iger-in-bob-chapek-out" }];
                    name = "link";
                    selfClosing = true;
                }),
                #startTag({
                    attributes = [];
                    name = "id";
                    selfClosing = false;
                }),
                #text("https://www.theverge.com/2022/11/20/23470368/disney-ceo-bob-iger-in-bob-chapek-out"),
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
                #text("Richard Lawler"),
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
                #text("2022-11-21T17:51:41-05:00"),
                #endTag({ name = "published" }),
                #startTag({
                    attributes = [];
                    name = "updated";
                    selfClosing = false;
                }),
                #text("2022-11-21T17:51:41-05:00"),
                #endTag({ name = "updated" }),
                #startTag({
                    attributes = [];
                    name = "title";
                    selfClosing = false;
                }),
                #text("The best Black Friday deals you can already get at Amazon"),
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
                    attributes = [{ name = "alt"; value = ?"Google’s Pixel Buds Pro earbuds, in yellow lemongrass color, resting at the foot of their white charging case on a tabletop." }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/iYwRuqLOBOqomCH1lG0lDWFheGA" }];
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
                #text("Amazon’s Black Friday discounts extend to more than just Amazon devices."),
                #endTag({ name = "em" }),
                #text("| Photo by Chris Welch / The Verge"),
                #endTag({ name = "figcaption" }),
                #endTag({ name = "figure" }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"aRKQfH" }];
                    name = "p";
                    selfClosing = false;
                }),
                #text("Black Friday is right around the corner, but Amazon is wasting no time by rolling out some excellent deals in the run-up to the main event on Friday. If you’re looking to knock out some of your holiday shopping early, we’ve rounded up a small collection of all the best discounts you can currently get on wireless headphones, 4K TVs, tablets, and more. "),
                #endTag({ name = "p" }),
                #startTag({
                    attributes = [{
                        name = "class";
                        value = ?"c-float-left c-float-hang";
                    }];
                    name = "div";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"ABSC8o" }];
                    name = "aside";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [{ name = "data-anthem-component"; value = ?"readmore" }, { name = "data-anthem-component-data"; value = ?"'{stories:[{title:The Verge Holiday Gift Guide 2022,url:https://www.theverge.com/23435489/holiday-gift-guide-best-ideas-cool-tech},{title:The best early Black Friday deals you can already get,url:https://www.theverge.com/23438688/black-friday-2022-best-early-deals-tech-tv-apple-smart-home},{title:Know the price-matching policies for Best Buy, Target, Walmart, and others,url:https://www.theverge.com/21570383/price-matching-policy-apple-google-microsoft}]}'" }];
                    name = "div";
                    selfClosing = false;
                }),
                #endTag({ name = "div" }),
                #endTag({ name = "aside" }),
                #endTag({ name = "div" }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"HtHGHM" }];
                    name = "p";
                    selfClosing = false;
                }),
                #text("If you’re looking for discounts at other retailers, we’ve also put together roundups of the best deals you can find ahead of Black Friday at"),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/e/23197114";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("Target"),
                #endTag({ name = "a" }),
                #text(","),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/e/23160805";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("Best Buy"),
                #endTag({ name = "a" }),
                #text(", and"),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/e/23204521";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("Walmart"),
                #endTag({ name = "a" }),
                #text(". To stay up to speed with everything happening over Black Friday and Cyber Monday, make sure to bookmark our"),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/e/23197880";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("Black Friday hub"),
                #endTag({ name = "a" }),
                #text("and check back for regular updates."),
                #endTag({ name = "p" }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"hjLr4p" }];
                    name = "div";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [{ name = "rel"; value = ?"stylesheet" }, { name = "href"; value = ?"https://s3.amazonaws.com/assets.sbnation.com/csk/uploads/verge-toc.css" }];
                    name = "link";
                    selfClosing = true;
                }),
                #startTag({
                    attributes = [{ name = "class"; value = ?"duet--article--article-body-component verge-table-of-contents border-franklin border" }, { name = "id"; value = ?"toc-main" }];
                    name = "div";
                    selfClosing = false;
                }),
                #endTag({ name = "div" }),
                #endTag({ name = "div" }),
                #startTag({
                    attributes = [{ name = "class"; value = ?"p-entry-hr" }, { name = "id"; value = ?"MUyQMv" }];
                    name = "hr";
                    selfClosing = true;
                }),
                #startTag({
                    attributes = [{ name = "id"; value = ?"oQgeHw" }];
                    name = "h2";
                    selfClosing = false;
                }),
                #text("The best Amazon Black Friday deals on Echo..."),
                #endTag({ name = "h2" }),
                #startTag({
                    attributes = [];
                    name = "p";
                    selfClosing = false;
                }),
                #startTag({
                    attributes = [{
                        name = "href";
                        value = ?"https://www.theverge.com/23466456/amazon-black-friday-2022-deals-cyber-monday-tech-games-tv";
                    }];
                    name = "a";
                    selfClosing = false;
                }),
                #text("Continue reading&hellip;"),
                #endTag({ name = "a" }),
                #endTag({ name = "p" }),
                #endTag({ name = "content" }),
                #startTag({
                    attributes = [{ name = "rel"; value = ?"alternate" }, { name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/23466456/amazon-black-friday-2022-deals-cyber-monday-tech-games-tv" }];
                    name = "link";
                    selfClosing = true;
                }),
                #startTag({
                    attributes = [];
                    name = "id";
                    selfClosing = false;
                }),
                #text("https://www.theverge.com/23466456/amazon-black-friday-2022-deals-cyber-monday-tech-games-tv"),
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
                #text("Alice Newcome-Beill"),
                #endTag({ name = "name" }),
                #endTag({ name = "author" }),
                #endTag({ name = "entry" }),
                #endTag({ name = "feed" }),
            ];

            doc : Types.Document = {
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
                                #text("The Verge - All Posts"),
                            ]);
                            name = "title";
                        }),
                        #element({
                            attributes = [];
                            children = #open([#text("https://cdn.vox-cdn.com/community_logos/52801/VER_Logomark_32x32..png")]);
                            name = "icon";
                        }),
                        #element({
                            attributes = [];
                            children = #open([#text("2022-11-21T21:30:42-05:00")]);
                            name = "updated";
                        }),
                        #element({
                            attributes = [];
                            children = #open([#text("https://www.theverge.com/rss/full.xml")]);
                            name = "id";
                        }),
                        #element({
                            attributes = [{ name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/" }, { name = "rel"; value = ?"alternate" }];
                            children = #selfClosing;
                            name = "link";
                        }),
                        #element({
                            attributes = [];
                            children = #open([#element({ attributes = []; children = #open([#text("2022-11-21T21:30:42-05:00")]); name = "published" }), #element({ attributes = []; children = #open([#text("2022-11-21T21:30:42-05:00")]); name = "updated" }), #element({ attributes = []; children = #open([#text("Twitter is making DMs encrypted and adding video, voice chat, per Elon Musk")]); name = "title" }), #element({ attributes = [{ name = "type"; value = ?"html" }]; children = #open([#element({ attributes = []; children = #open([#element({ attributes = [{ name = "alt"; value = ?"An illustration of the Twitter logo" }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/6kBqimyOvt-iCvNDVhv2okF4ey4" }]; children = #selfClosing; name = "img" }), #element({ attributes = []; children = #open([#text("Illustration by Alex Castro / The Verge")]); name = "figcaption" })]); name = "figure" }), #element({ attributes = [{ name = "id"; value = ?"TvAhZo" }]; children = #open([#text("Twitter’s new owner, Elon Musk, has been public about his desire to improve how the social network’s direct messages work. In a meeting with employees today, he spelled out exactly what that looks like.")]); name = "p" }), #element({ attributes = [{ name = "id"; value = ?"6MmlUD" }]; children = #open([#text("Framed by presentation slides titled “Twitter 2.0” at Twitter’s San Fransisco headquarters on Monday, Musk told employees that the company would encrypt DMs and work to add encrypted video and voice calling between accounts, according to a recording of the meeting obtained by"), #element({ attributes = []; children = #open([#text("The Verge")]); name = "em" }), #text(".")]); name = "p" }), #element({ attributes = [{ name = "id"; value = ?"Z8NlgY" }]; children = #open([#text("“We want to enable users to be able to communicate without being concerned about their privacy, [or] without being concerned about a data breach at Twitter causing all of their DMs to hit the web, or think that maybe someone at Twitter could be spying on...")]); name = "p" }), #element({ attributes = []; children = #open([#element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling" }]; children = #open([#text("Continue reading&hellip;")]); name = "a" })]); name = "p" })]); name = "content" }), #element({ attributes = [{ name = "rel"; value = ?"alternate" }, { name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling" }]; children = #selfClosing; name = "link" }), #element({ attributes = []; children = #open([#text("https://www.theverge.com/2022/11/21/23472174/twitter-dms-encrypted-elon-musk-voice-video-calling")]); name = "id" }), #element({ attributes = []; children = #open([#element({ attributes = []; children = #open([#text("Alex Heath")]); name = "name" })]); name = "author" })]);
                            name = "entry";
                        }),
                        #element({
                            attributes = [];
                            children = #open([#element({ attributes = []; children = #open([#text("2022-11-21T20:24:25-05:00")]); name = "published" }), #element({ attributes = []; children = #open([#text("2022-11-21T20:24:25-05:00")]); name = "updated" }), #element({ attributes = []; children = #open([#text("Domino’s is building an all-electric pizza delivery fleet with Chevy Bolts")]); name = "title" }), #element({ attributes = [{ name = "type"; value = ?"html" }]; children = #open([#element({ attributes = []; children = #open([#element({ attributes = [{ name = "alt"; value = ?"Two chevy bolt ev cars, wrapped in domino’s artwork are parked in front of a domino’s pizza store with one of the cars hooked up to a charger." }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/uraUyO3VeLJ8RJ6ethB54sPF1bs" }]; children = #selfClosing; name = "img" }), #element({ attributes = []; children = #open([#element({ attributes = []; children = #open([#text("Domino’s outfitted Chevy Bolts.")]); name = "em" }), #text("| Image: Domino’s")]); name = "figcaption" })]); name = "figure" }), #element({ attributes = [{ name = "id"; value = ?"1PMpbG" }]; children = #open([#text("Domino’s is gearing up to put"), #element({ attributes = [{ name = "href"; value = ?"https://ir.dominos.com/news-releases/news-release-details/dominosr-roll-out-nationwide-fleet-800-chevy-boltr-electric" }]; children = #open([#text("more than 800 all-electric pizza delivery vehicles into service")]); name = "a" }), #text("in the coming months, starting with over 100 of them rolling out in November. The company went with the compact Chevy Bolt EV and is wrapping the vehicles with custom branding but no other bells and whistles — just combustion-free deliveries (via"), #element({ attributes = [{ name = "href"; value = ?"https://electrek.co/2022/11/21/dominos-acquires-800-chevy-bolts-evs-for-delivery-fleet/" }]; children = #open([#element({ attributes = []; children = #open([#text("electrek")]); name = "em" })]); name = "a" }), #text(").")]); name = "p" }), #element({ attributes = [{ name = "id"; value = ?"Lo1Jmp" }]; children = #open([#text("Domino will have a fleet of 855 new electric vehicles, to be exact, and while that’s not quite enough to reach"), #element({ attributes = [{ name = "href"; value = ?"https://ir.dominos.com/static-files/4daec873-268e-4456-b541-3871f28288e2" }]; children = #open([#text("all 6,135 of the pizza shops in the US")]); name = "a" }), #text(", it's more than the Chevy Spark-based (gas version) ones it built with"), #element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/2015/10/21/9587270/dominos-dxp-delivery-car-chevy-spark-pizza" }]; children = #open([#text("custom pizza warming oven doors")]); name = "a" }), #text("in 2015. Those were called the Domino’s DXP, and only 155 of them were made. For the new Bolts, drivers will need to toss the HeatWave bags in...")]); name = "p" }), #element({ attributes = []; children = #open([#element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout" }]; children = #open([#text("Continue reading&hellip;")]); name = "a" })]); name = "p" })]); name = "content" }), #element({ attributes = [{ name = "rel"; value = ?"alternate" }, { name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout" }]; children = #selfClosing; name = "link" }), #element({ attributes = []; children = #open([#text("https://www.theverge.com/2022/11/21/23472002/dominos-chevy-bolt-ev-pizza-delivery-fleet-rollout")]); name = "id" }), #element({ attributes = []; children = #open([#element({ attributes = []; children = #open([#text("Umar Shakir")]); name = "name" })]); name = "author" })]);
                            name = "entry";
                        }),
                        #element({
                            attributes = [];
                            children = #open([#element({ attributes = []; children = #open([#text("2022-11-21T19:44:46-05:00")]); name = "published" }), #element({ attributes = []; children = #open([#text("2022-11-21T19:44:46-05:00")]); name = "updated" }), #element({ attributes = []; children = #open([#text("Elon Musk bought Twitter, and here’s everything that happened next")]); name = "title" }), #element({ attributes = [{ name = "type"; value = ?"html" }]; children = #open([#element({ attributes = []; children = #open([#element({ attributes = [{ name = "alt"; value = ?"" }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/gOLos_N33sgfTa2gWSVdcAxcqt0" }]; children = #selfClosing; name = "img" }), #element({ attributes = []; children = #open([#text("Laura Normand / The Verge")]); name = "figcaption" })]); name = "figure" }), #element({ attributes = []; children = #open([#text("Elon Musk is now the owner, CEO, and sole director of Twitter. His “Twitter 2.0” era has so far included mass layoffs and rapidly changing policy decisions.")]); name = "p" }), #element({ attributes = []; children = #open([#element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/2022/4/11/23019836/elon-musk-twitter-board-of-directors-news-updates" }]; children = #open([#text("Continue reading&hellip;")]); name = "a" })]); name = "p" })]); name = "content" }), #element({ attributes = [{ name = "rel"; value = ?"alternate" }, { name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/2022/4/11/23019836/elon-musk-twitter-board-of-directors-news-updates" }]; children = #selfClosing; name = "link" }), #element({ attributes = []; children = #open([#text("https://www.theverge.com/2022/4/11/23019836/elon-musk-twitter-board-of-directors-news-updates")]); name = "id" }), #element({ attributes = []; children = #open([#element({ attributes = []; children = #open([#text("Alex Heath")]); name = "name" }), #element({ attributes = []; children = #open([#text("Emma Roth")]); name = "name" }), #element({ attributes = []; children = #open([#text("James Vincent")]); name = "name" }), #element({ attributes = []; children = #open([#text("Sean Hollister")]); name = "name" }), #element({ attributes = []; children = #open([#text("Nilay Patel")]); name = "name" }), #element({ attributes = []; children = #open([#text("Mitchell Clark")]); name = "name" }), #element({ attributes = []; children = #open([#text("Richard Lawler")]); name = "name" }), #element({ attributes = []; children = #open([#text("Russell Brandom")]); name = "name" }), #element({ attributes = []; children = #open([#text("Elizabeth Lopatto")]); name = "name" }), #element({ attributes = []; children = #open([#text("Thomas Ricker")]); name = "name" }), #element({ attributes = []; children = #open([#text("Mia Sato")]); name = "name" })]); name = "author" })]);
                            name = "entry";
                        }),
                        #element({
                            attributes = [];
                            children = #open([#element({ attributes = []; children = #open([#text("2022-11-21T19:31:11-05:00")]); name = "published" }), #element({ attributes = []; children = #open([#text("2022-11-21T19:31:11-05:00")]); name = "updated" }), #element({ attributes = []; children = #open([#text("Twitter won’t restart paid verification until ‘significant impersonations’ stop, Elon Musk says")]); name = "title" }), #element({ attributes = [{ name = "type"; value = ?"html" }]; children = #open([#element({ attributes = []; children = #open([#element({ attributes = [{ name = "alt"; value = ?"An illustration of the Twitter logo." }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/zQLVeU7EwVTBQLHivgfUFyqWqvM" }]; children = #selfClosing; name = "img" }), #element({ attributes = []; children = #open([#text("Illustration by Alex Castro / The Verge")]); name = "figcaption" })]); name = "figure" }), #element({ attributes = [{ name = "id"; value = ?"InvXEX" }]; children = #open([#text("Elon Musk told Twitter employees on Monday that the company won’t relaunch its paid verification subscription, Twitter Blue, until “we’re confident about significant impersonations not happening,” according to a recording of his remarks obtained by"), #element({ attributes = []; children = #open([#text("The Verge")]); name = "em" }), #text(".")]); name = "p" }), #element({ attributes = [{ name = "id"; value = ?"iN7NAx" }]; children = #open([#text("Musk said last week that his $8 per month Blue subscription"), #element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/2022/11/15/23461244/twitter-blue-relaunch-verification-elon-musk" }]; children = #open([#text("would be made available again on November 29th")]); name = "a" }), #text(". But in the meeting with employees, he said the timing of the launch was unclear: “We might launch it next week. We might not. But we’re not going to launch until there’s high confidence in protecting against those significant impersonations.”")]); name = "p" }), #element({ attributes = [{ name = "id"; value = ?"Le0vLW" }]; children = #open([#text("After taking over Twitter, Musk’s first big change was to quickly introduce the ability for users to buy a blue checkmark through...")]); name = "p" }), #element({ attributes = []; children = #open([#element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/2022/11/21/23472184/elon-musk-twitter-paid-verification-relaunch-delay-impersonations" }]; children = #open([#text("Continue reading&hellip;")]); name = "a" })]); name = "p" })]); name = "content" }), #element({ attributes = [{ name = "rel"; value = ?"alternate" }, { name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/2022/11/21/23472184/elon-musk-twitter-paid-verification-relaunch-delay-impersonations" }]; children = #selfClosing; name = "link" }), #element({ attributes = []; children = #open([#text("https://www.theverge.com/2022/11/21/23472184/elon-musk-twitter-paid-verification-relaunch-delay-impersonations")]); name = "id" }), #element({ attributes = []; children = #open([#element({ attributes = []; children = #open([#text("Alex Heath")]); name = "name" })]); name = "author" })]);
                            name = "entry";
                        }),
                        #element({
                            attributes = [];
                            children = #open([#element({ attributes = []; children = #open([#text("2022-11-21T19:00:00-05:00")]); name = "published" }), #element({ attributes = []; children = #open([#text("2022-11-21T19:00:00-05:00")]); name = "updated" }), #element({ attributes = []; children = #open([#text("Apple changed how reading books works in iOS 16, and I may never be happy again")]); name = "title" }), #element({ attributes = [{ name = "type"; value = ?"html" }]; children = #open([#element({ attributes = []; children = #open([#element({ attributes = [{ name = "alt"; value = ?"Nilay Patel holds an iPhone 14 Pro in his hands." }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/fy-1OSl08rP0neOAsPVBx3gB7kM" }]; children = #selfClosing; name = "img" }), #element({ attributes = []; children = #open([#element({ attributes = []; children = #open([#text("Am I being dramatic? Yes. Has this change made me read on my phone less? Also yes.")]); name = "em" }), #text("| Photo by Amelia Holowaty Krales / The Verge")]); name = "figcaption" })]); name = "figure" }), #element({ attributes = [{ name = "id"; value = ?"NwS67V" }]; children = #open([#text("Apple Books has been my main reading app for years for one very specific reason: its page-turning animation is far and away the best in the business. Unfortunately, that went away with iOS 16 and has been replaced by a new animation that makes it feel like you’re moving cards through a deck instead of leafing through a digitized version of paper. And despite the fact that I’ve been trying to get used to the change since I got onto the beta in July, I still feel like Apple’s destroyed one of the last ways that my phone brought joy into my life.")]); name = "p" }), #element({ attributes = [{ name = "id"; value = ?"ed6BLz" }]; children = #open([#text("For those unfamiliar with Apple’s Books app (formerly known as iBooks), I’ll try to explain the hole that’s suddenly been punched into my reading life. Before iOS 16, the app would play a...")]); name = "p" }), #element({ attributes = []; children = #open([#element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/2022/11/21/23471306/apple-books-ios-16-page-flip-animation-sucks" }]; children = #open([#text("Continue reading&hellip;")]); name = "a" })]); name = "p" })]); name = "content" }), #element({ attributes = [{ name = "rel"; value = ?"alternate" }, { name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/2022/11/21/23471306/apple-books-ios-16-page-flip-animation-sucks" }]; children = #selfClosing; name = "link" }), #element({ attributes = []; children = #open([#text("https://www.theverge.com/2022/11/21/23471306/apple-books-ios-16-page-flip-animation-sucks")]); name = "id" }), #element({ attributes = []; children = #open([#element({ attributes = []; children = #open([#text("Mitchell Clark")]); name = "name" })]); name = "author" })]);
                            name = "entry";
                        }),
                        #element({
                            attributes = [];
                            children = #open([#element({ attributes = []; children = #open([#text("2022-11-21T18:46:49-05:00")]); name = "published" }), #element({ attributes = []; children = #open([#text("2022-11-21T18:46:49-05:00")]); name = "updated" }), #element({ attributes = []; children = #open([#text("iOS developers say Apple’s App Store analytics aren’t anonymous")]); name = "title" }), #element({ attributes = [{ name = "type"; value = ?"html" }]; children = #open([#element({ attributes = []; children = #open([#element({ attributes = [{ name = "alt"; value = ?"" }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/eYqZ0c_m283srxzRlmzfjkoh_pQ" }]; children = #selfClosing; name = "img" }), #element({ attributes = []; children = #open([#text("Image: Apple")]); name = "figcaption" })]); name = "figure" }), #element({ attributes = [{ name = "id"; value = ?"xinbTn" }]; children = #open([#text("The detailed analytics data Apple records about what you do in the App Store can be tied directly to your Apple account, according to app development and research team Mysk. In"), #element({ attributes = [{ name = "href"; value = ?"https://twitter.com/mysk_co/status/1594515229915979776" }]; children = #open([#text("a Twitter thread")]); name = "a" }), #text(", Mysk shows that Apple sends what’s known as a “Directory Services Identifier” along with its App Store analytics info and argues that the identifier is also tied to your iCloud account, linking your name, email address, and more.")]); name = "p" }), #element({ attributes = [{ name = "id"; value = ?"zrD2cY" }]; children = #open([#text("The thread also notes that the data is still sent even if you turn off device analytics in settings, and that Apple sends your DSID in other apps as well. In the last tweet in the thread, Mysk says: “You just need to know three things: 1- The App Store sends detailed analytics about you to Apple. 2- There’s no way to...")]); name = "p" }), #element({ attributes = []; children = #open([#element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/2022/11/21/23471827/apple-app-store-data-collection-analytics-personal-info-privacy" }]; children = #open([#text("Continue reading&hellip;")]); name = "a" })]); name = "p" })]); name = "content" }), #element({ attributes = [{ name = "rel"; value = ?"alternate" }, { name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/2022/11/21/23471827/apple-app-store-data-collection-analytics-personal-info-privacy" }]; children = #selfClosing; name = "link" }), #element({ attributes = []; children = #open([#text("https://www.theverge.com/2022/11/21/23471827/apple-app-store-data-collection-analytics-personal-info-privacy")]); name = "id" }), #element({ attributes = []; children = #open([#element({ attributes = []; children = #open([#text("Mitchell Clark")]); name = "name" })]); name = "author" })]);
                            name = "entry";
                        }),
                        #element({
                            attributes = [];
                            children = #open([#element({ attributes = []; children = #open([#text("2022-11-21T18:03:32-05:00")]); name = "published" }), #element({ attributes = []; children = #open([#text("2022-11-21T18:03:32-05:00")]); name = "updated" }), #element({ attributes = []; children = #open([#text("Bob Iger steps back in as Disney CEO, replacing Bob Chapek ")]); name = "title" }), #element({ attributes = [{ name = "type"; value = ?"html" }]; children = #open([#element({ attributes = []; children = #open([#element({ attributes = [{ name = "alt"; value = ?"A colorful graphical illustration of the Disney Plus logo." }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/LBZpzWdUUjxgvybEwhbunWt_HHw" }]; children = #selfClosing; name = "img" }), #element({ attributes = []; children = #open([#text("Illustration by Alex Castro / The Verge")]); name = "figcaption" })]); name = "figure" }), #element({ attributes = [{ name = "id"; value = ?"SOoXw3" }]; children = #open([#text("In a sudden turn of events, Disney has reversed"), #element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/2020/2/25/21153317/bob-iger-disney-ceo-steps-down-chapek-kevin-mayer-parks-products-succession" }]; children = #open([#text("the CEO swap that surprised us in early 2020")]); name = "a" }), #text(", with Bob Iger"), #element({ attributes = [{ name = "href"; value = ?"https://thewaltdisneycompany.com/the-walt-disney-company-board-of-directors-appoints-robert-a-iger-as-chief-executive-officer/" }]; children = #open([#text("returning to his post")]); name = "a" }), #text(", replacing his own successor, Bob Chapek. Iger, who is also the company’s largest shareholder, is now set to serve a new two-year term as CEO. Part of Iger’s job in those two years will be to pick and groom his long-term successor.")]); name = "p" }), #element({ attributes = [{ name = "id"; value = ?"v6tlhA" }]; children = #open([#text("Of course, Chapek was an Iger choice too. Chapek"), #element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/2020/2/26/21153579/disney-ceo-bob-iger-chapek-mayer-streaming-succession-tim-cook-steve-jobs" }]; children = #open([#text("had been called the “Tim Cook to Iger’s Steve Jobs,”")]); name = "a" }), #text("but during his tenure, their handover got off to a rocky start, while blowups like the"), #element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/2021/7/29/22600396/scarlett-johansson-suing-disney-black-widow-release" }]; children = #open([#text("Scarlett Johansson"), #element({ attributes = []; children = #open([#text("Black Widow")]); name = "em" }), #text("lawsuit")]); name = "a" }), #text("and Disney’s initial lack of reaction to the “Don’t Say Gay” bill in Florida scuffed its all-important reputation.")]); name = "p" }), #element({ attributes = [{ name = "class"; value = ?"c-float-left c-float-hang" }]; children = #open([#element({ attributes = [{ name = "id"; value = ?"KHz6gw" }]; children = #open([]); name = "div" })]); name = "div" }), #element({ attributes = [{ name = "id"; value = ?"2JSx2D" }]; children = #open([#text("During"), #element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/23010559/decoder-streaming-platforms-cable-netflix-disney-apple" }]; children = #open([#text("an episode of the"), #element({ attributes = []; children = #open([#text("Decoder ")]); name = "em" }), #text("podcast...")]); name = "a" })]); name = "p" }), #element({ attributes = []; children = #open([#element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/2022/11/20/23470368/disney-ceo-bob-iger-in-bob-chapek-out" }]; children = #open([#text("Continue reading&hellip;")]); name = "a" })]); name = "p" })]); name = "content" }), #element({ attributes = [{ name = "rel"; value = ?"alternate" }, { name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/2022/11/20/23470368/disney-ceo-bob-iger-in-bob-chapek-out" }]; children = #selfClosing; name = "link" }), #element({ attributes = []; children = #open([#text("https://www.theverge.com/2022/11/20/23470368/disney-ceo-bob-iger-in-bob-chapek-out")]); name = "id" }), #element({ attributes = []; children = #open([#element({ attributes = []; children = #open([#text("Richard Lawler")]); name = "name" })]); name = "author" })]);
                            name = "entry";
                        }),
                        #element({
                            attributes = [];
                            children = #open([#element({ attributes = []; children = #open([#text("2022-11-21T17:51:41-05:00")]); name = "published" }), #element({ attributes = []; children = #open([#text("2022-11-21T17:51:41-05:00")]); name = "updated" }), #element({ attributes = []; children = #open([#text("The best Black Friday deals you can already get at Amazon")]); name = "title" }), #element({ attributes = [{ name = "type"; value = ?"html" }]; children = #open([#element({ attributes = []; children = #open([#element({ attributes = [{ name = "alt"; value = ?"Google’s Pixel Buds Pro earbuds, in yellow lemongrass color, resting at the foot of their white charging case on a tabletop." }, { name = "src"; value = ?"https://cdn.vox-cdn.com/thumbor/iYwRuqLOBOqomCH1lG0lDWFheGA" }]; children = #selfClosing; name = "img" }), #element({ attributes = []; children = #open([#element({ attributes = []; children = #open([#text("Amazon’s Black Friday discounts extend to more than just Amazon devices.")]); name = "em" }), #text("| Photo by Chris Welch / The Verge")]); name = "figcaption" })]); name = "figure" }), #element({ attributes = [{ name = "id"; value = ?"aRKQfH" }]; children = #open([#text("Black Friday is right around the corner, but Amazon is wasting no time by rolling out some excellent deals in the run-up to the main event on Friday. If you’re looking to knock out some of your holiday shopping early, we’ve rounded up a small collection of all the best discounts you can currently get on wireless headphones, 4K TVs, tablets, and more. ")]); name = "p" }), #element({ attributes = [{ name = "class"; value = ?"c-float-left c-float-hang" }]; children = #open([#element({ attributes = [{ name = "id"; value = ?"ABSC8o" }]; children = #open([#element({ attributes = [{ name = "data-anthem-component"; value = ?"readmore" }, { name = "data-anthem-component-data"; value = ?"'{stories:[{title:The Verge Holiday Gift Guide 2022,url:https://www.theverge.com/23435489/holiday-gift-guide-best-ideas-cool-tech},{title:The best early Black Friday deals you can already get,url:https://www.theverge.com/23438688/black-friday-2022-best-early-deals-tech-tv-apple-smart-home},{title:Know the price-matching policies for Best Buy, Target, Walmart, and others,url:https://www.theverge.com/21570383/price-matching-policy-apple-google-microsoft}]}'" }]; children = #open([]); name = "div" })]); name = "aside" })]); name = "div" }), #element({ attributes = [{ name = "id"; value = ?"HtHGHM" }]; children = #open([#text("If you’re looking for discounts at other retailers, we’ve also put together roundups of the best deals you can find ahead of Black Friday at"), #element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/e/23197114" }]; children = #open([#text("Target")]); name = "a" }), #text(","), #element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/e/23160805" }]; children = #open([#text("Best Buy")]); name = "a" }), #text(", and"), #element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/e/23204521" }]; children = #open([#text("Walmart")]); name = "a" }), #text(". To stay up to speed with everything happening over Black Friday and Cyber Monday, make sure to bookmark our"), #element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/e/23197880" }]; children = #open([#text("Black Friday hub")]); name = "a" }), #text("and check back for regular updates.")]); name = "p" }), #element({ attributes = [{ name = "id"; value = ?"hjLr4p" }]; children = #open([#element({ attributes = [{ name = "rel"; value = ?"stylesheet" }, { name = "href"; value = ?"https://s3.amazonaws.com/assets.sbnation.com/csk/uploads/verge-toc.css" }]; children = #selfClosing; name = "link" }), #element({ attributes = [{ name = "class"; value = ?"duet--article--article-body-component verge-table-of-contents border-franklin border" }, { name = "id"; value = ?"toc-main" }]; children = #open([]); name = "div" })]); name = "div" }), #element({ attributes = [{ name = "class"; value = ?"p-entry-hr" }, { name = "id"; value = ?"MUyQMv" }]; children = #selfClosing; name = "hr" }), #element({ attributes = [{ name = "id"; value = ?"oQgeHw" }]; children = #open([#text("The best Amazon Black Friday deals on Echo...")]); name = "h2" }), #element({ attributes = []; children = #open([#element({ attributes = [{ name = "href"; value = ?"https://www.theverge.com/23466456/amazon-black-friday-2022-deals-cyber-monday-tech-games-tv" }]; children = #open([#text("Continue reading&hellip;")]); name = "a" })]); name = "p" })]); name = "content" }), #element({ attributes = [{ name = "rel"; value = ?"alternate" }, { name = "type"; value = ?"text/html" }, { name = "href"; value = ?"https://www.theverge.com/23466456/amazon-black-friday-2022-deals-cyber-monday-tech-games-tv" }]; children = #selfClosing; name = "link" }), #element({ attributes = []; children = #open([#text("https://www.theverge.com/23466456/amazon-black-friday-2022-deals-cyber-monday-tech-games-tv")]); name = "id" }), #element({ attributes = []; children = #open([#element({ attributes = []; children = #open([#text("Alice Newcome-Beill")]); name = "name" })]); name = "author" })]);
                            name = "entry";
                        }),
                    ]);
                    name = "feed";
                };
                standalone = null;
                version = ?{ major = 1; minor = 0 };
                docType = null;
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
        {
            name = "Unescaped & character";
            error = "Unexpected character '&'";
            rawXml = "<root>&</root>";
        },
    ];

    public type ParsingFailExample = {
        name : Text;
        error : Parser.ParseError;
        tokens : [Types.Token];
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
