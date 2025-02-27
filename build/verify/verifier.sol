//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.11;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [15154384317996571869735848182202146825358081271565161972072363650553220775837,
             20421336938466048559628199133265608353249177540907882986055154213181100240597],
            [20747824983903356962809765575056646215561263068353806239195819200091580304516,
             15548515175472463742086816745546520604749369300680603610074363663683952230946]
        );
        vk.IC = new Pairing.G1Point[](73);
        
        vk.IC[0] = Pairing.G1Point( 
            12103163390268562097058922875516308663734054384457600615489970862819020936382,
            18799302325138575305730925128856638466547548677151609756861241516692851310491
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            7297137766618326693793354201070181657962011760824902905711254617389930101855,
            6861789181739367163998410065477882677752618961334085103954497249230350659817
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            19258060425207489754178034499076352064770296968657365190280776389404301085290,
            14352600742285526614277900756324229692423833844868075051061415302578745973255
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            20323459534268580832043325144989154736417323541991673661653541423725100308726,
            2123085714105117636542894816257175449073757429805907483436029207894092410215
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            18660836496862565635490984992468431961606688148043699631078941655522388903044,
            2024279881098248839231726532377896304840784756334511621000933246661705695702
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            8717308656791703783692037544631517551988697231861383306603822895572978880419,
            16240785993634769869813050002449359891776321797082338404398438246819753320361
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            18446440048231841411288326310398241241923817215645553021924023953381600091715,
            17065220643102945224934921208546580338206310525333301754461251464690454985901
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            15623720759167254230707699322738300077335389587869726360713535716976146975166,
            10419930951077005586540065114589007839947493427201725986875571360638036677440
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            1808943002184798705838772560983985173277059700274616629165935921281245415251,
            19988960232797671067576475059003966599294406201263774684747497671726755652992
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            1504137761627029727341447634336870465104886283507801954910693643943620952854,
            14828620727014325821832627217118499734142943929703387442830333536047511971830
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            14697106574142646007773614992532373974336427427280316134138890991243236565540,
            9357390436155878136444769675705329817503544742519709281203586985242357699037
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            13817394422145762846304889329726443510738967178398775476195055474295750725045,
            21594295484726526645630645349386432741895979710061856724290373177279145722510
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            1992202836580084384057765229926272637022791381762040355785372903525503309510,
            7494995175637620221972341714982811960827740532945186612440295303872081270370
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            10927347675713953452264496594763844931863714653830402063540478071419254845739,
            8891337085561222929768365801527176412065741260239062643693228420188541017928
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            6034665041357520205805804333706494354519129137596137429759000328129716152116,
            4189376347051211632000886689112358316198087576540690477451588612518429022471
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            18688175600249066290174544812987414841592721092681697008291559115040901077521,
            20129755705904294440184274916044125497807154603276497883308262243615799236268
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            9802065710018214652012855417999497457681694858490087042469721857034984331447,
            3058414145740014585355280197177629272693172254196261674968527265629060701732
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            15812652695272124174949226584071641132087549544972793302363525633834772386325,
            1107562703905232763143309898808558297671024521118355553388733563803247555585
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            9274747660323444806097695185946125129345867354271545906533026200174548613091,
            21451148442391355633905439337581202262601556871037262034260552928651408930789
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            6682577633763971945919730364907519542595065427888531293507794886211789765398,
            8020608754899449364136204950433232829638537846811552744312726114893399732610
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            5940109826235882154757090842953182054671926990318891680282969755189531414146,
            10060452564296228365753699772829547651073193990159072117410806904617521338424
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            9332271824898448382996403843888753453576278970536410768684069933535721502773,
            13003844898787647138487527853641173014158555685776879824923670929419823160849
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            4022723067508473673697001169880715974493349464447386552978386053839067279798,
            19470021437363027806609999235554630085077923415162696436289762490785090250798
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            20062397321807390131485968497813947390750212203269322764816652113040450356064,
            16906080631574137634721050870404823171913089658392186875089042296778482508573
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            1115295304337906571786866412612697205827153387274061592602294309448872829056,
            10121088877338202192205377961766706585446805050880297361756170263776046186512
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            16449539656839540192879143784918309950651806318899872605574336079536097798281,
            7233465739646794283379648311261202145242309131391111520969471191454836365883
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            7021127171539968132184643482030797940081964899610060558923569931927244613053,
            6038516833425942940118799905401617226147060938776680680415890636652628868068
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            7423974358732648653917402155560468943228667842006099676227994038610128386729,
            504142221475149396624852443576643453054552855300191365017296399682579205771
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            16519255605584404236693095673523445090883422789393888028505288815483998659146,
            5053300540874741577775458451693905635183962168254134155810789737368523872570
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            16304672436722675708919877363070156604825177629280477469108876176158570498278,
            21682684962164023819669263062760044271278328873768122855618463370746464414639
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            6836947629048506171282776401639483453925317170424304736146978961777261911658,
            19073231004071063899403060317083925528116713202698183358354685251127339719757
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            12593215231385526716012591552670148579485224884673975323142123875433592736336,
            14170428906782819973184523011607822456197788765948464558976976988439336054235
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            3919949013149187447370396706661711223945494503604051548958267801448449685458,
            19541556973783879388308874848246212844338715673931540220215350478424943797905
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            4074713173473147260735247804778414956707859735496686767560201819987183642599,
            8340981451750953995348988454322761689204435021734211429779183652589814113363
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            10316677047799182980649960252271266390188968280664517768780938306193137699258,
            6085958620404171629087512498831335847236258577645858780157564393913243121110
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            8967656892585587193748509782844689105788371535334723220330232790002561133543,
            12291762398106922542130580666535679530004304373848823962805226284132456289732
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            8817424718365691290461643670049924047039591183844927776315213866202795712254,
            12648527751709022457822137021632237558228901691352976384673454300285144511663
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            3904802635705381301417463003968974652840557089421207974097470424234321321330,
            17757542260288793762705826421586466371857199771104148321100311230965284730800
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            166974503512658241095079735711939015954120322667129714522777076875053023284,
            15389133540698015227952722635421942498735304624918755347876413739498637209714
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            19720057471360663082772687495270375596706359411004223303364865729001427555498,
            12826605496642114843063024807347172315985948097244939889842611309647038071615
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            21793835475091922944556760333879417278393435506238090936206308960746252790904,
            10618032013171392064716009492536740172455993646938609918105691702895440901715
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            20161902492689553309664788016982437621771451384409971439047097120229690181403,
            13515556330718805954120075582520589368562516959191123578869912697500989303739
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            2594361218067639800787889159702567409742771805462515258531237913616847140059,
            6405969174461092701837188207371637751978541024580854556053037876739556908714
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            16225731273737369587156075735028321626846773312224368081635772316834680122935,
            9104389330192097631747882949230100848533676873189218011598792761797067664248
        );                                      
        
        vk.IC[44] = Pairing.G1Point( 
            21857414796252539754321328421119840989416400368482586731525210100061493972175,
            6297753369876108166125843044780030844192609085910064479969179477971976249704
        );                                      
        
        vk.IC[45] = Pairing.G1Point( 
            18666714138562841869603608801011626718718047716437129613143816034411474777756,
            7102889129988653543495319888014721300217133096659983114885673088228393140155
        );                                      
        
        vk.IC[46] = Pairing.G1Point( 
            12043746324446727040892971621676368506440141510243225399785074521739673295489,
            13272298324536688356310100605773534687095409830415561048059051972281799709616
        );                                      
        
        vk.IC[47] = Pairing.G1Point( 
            3931534996064816476240179825286677036179013760602488134923541893117812425429,
            18107273782253897348622364336981579949890554342554905301636845293315404402306
        );                                      
        
        vk.IC[48] = Pairing.G1Point( 
            16197395226775353259049066561673371942037639590603857528264806403940942571485,
            6554230283132347282478925835385513927457773624997879593058442960334324601038
        );                                      
        
        vk.IC[49] = Pairing.G1Point( 
            11362758076559533241829591651292421768783999449195297679213583417406004059503,
            20173553719733826605716739199594170103555794407854821193269730275751366593268
        );                                      
        
        vk.IC[50] = Pairing.G1Point( 
            4424336677679136882816229718978680475439851637293788436752089364069891489165,
            19461563866283010468753844604959055854133522556332463655444885225528179000873
        );                                      
        
        vk.IC[51] = Pairing.G1Point( 
            18891238594009631090353366734467044502044453986646848061608171430650069849126,
            8424187339036671333762524996175592312010621380354264297114523970498291916748
        );                                      
        
        vk.IC[52] = Pairing.G1Point( 
            20394479147603862047781834797956206758970721197247775017154667149243182630236,
            15094433389921337720199862901059446071390828840713558658928468126147774566807
        );                                      
        
        vk.IC[53] = Pairing.G1Point( 
            3314243703155150136178028874413077705910872594826631224816693274903980627269,
            6081638051454785067827210223648173002871035360526873760813946098307042782759
        );                                      
        
        vk.IC[54] = Pairing.G1Point( 
            18731473965729049049122771262868152010938323165045284341124292940038580748258,
            6136494057033083843230546108630550432660571345533736227871175190240029458210
        );                                      
        
        vk.IC[55] = Pairing.G1Point( 
            8373142098573854459261693188317887100604905373802287831251148483732928987121,
            9430566458939449396199501404893131854300801294329021230380153645308927176950
        );                                      
        
        vk.IC[56] = Pairing.G1Point( 
            20732880931720312900348129759477252379673589926816670612702979730208661950425,
            21437015137725384291526889078356926926617660917418619201510605182084542241589
        );                                      
        
        vk.IC[57] = Pairing.G1Point( 
            20733529823944513718511329029978576198752625487767027551794845252612879876619,
            15303437508961502831808000019013221457151235132948260940447350568529634876013
        );                                      
        
        vk.IC[58] = Pairing.G1Point( 
            2754758547754466020985160457884473085370125362014937471463448970710836699831,
            14610449661760014045572234159760695319048074042184461428664027531941851491943
        );                                      
        
        vk.IC[59] = Pairing.G1Point( 
            5474144344789141800974293954500983661865564403201304459802477272680251260749,
            12478328839294004388358649355224961432333769504417645783105634017324091880290
        );                                      
        
        vk.IC[60] = Pairing.G1Point( 
            15143358508194136912953991437915644768892377811287556595668110104116840891169,
            1919896780561558399157174746299436218421513870784451859660942336378335163089
        );                                      
        
        vk.IC[61] = Pairing.G1Point( 
            2199545842654682367492592818232108409323277812226797044298399145135004594132,
            1869661935803603160557952497442287623000085473015748909667330444315803022350
        );                                      
        
        vk.IC[62] = Pairing.G1Point( 
            11086660714121093370590976280881172455916171025302140101214467974231656084139,
            7211558859254987404054008656986790969585462447492265483289975576314976638648
        );                                      
        
        vk.IC[63] = Pairing.G1Point( 
            9495007054386206149961478924531336592518154904500413732552514056893111744524,
            1479890627757013946196770590987912151327077774370671655186007346788891095898
        );                                      
        
        vk.IC[64] = Pairing.G1Point( 
            16476422136256598487493236267515560597909731214282301311377900163841602858214,
            7056819653143566863639571287564275449869627388241540281299805962703151152815
        );                                      
        
        vk.IC[65] = Pairing.G1Point( 
            6064961180551366556584044934759759228258166020096713288829200973074411928913,
            13151737388427685757758544238789393803678035329319009195267890502103552689996
        );                                      
        
        vk.IC[66] = Pairing.G1Point( 
            10196833010477958771195862935069252301790781945067572031858864633447398341745,
            8656071636746091840249645733943688515743662988035592435441995781999268498996
        );                                      
        
        vk.IC[67] = Pairing.G1Point( 
            15263291710191289942163475920814569264514235042722997495046348041624906123150,
            11399678690606707806005479245811512725637199436979653977552987276199962730245
        );                                      
        
        vk.IC[68] = Pairing.G1Point( 
            20355450746540432411158624211395577774126040977978622478222777489685045400622,
            3996236484041231470345424850177221434127907356758855512444462865383419888640
        );                                      
        
        vk.IC[69] = Pairing.G1Point( 
            10912368234992753624562878186482944538938952817440310668469586012072552727847,
            17653234697264495766819308716471023494451951537588940874141922021036975548328
        );                                      
        
        vk.IC[70] = Pairing.G1Point( 
            1220165872085692563037511019507064399496235810674178417260560581524672820739,
            14596366021088999958292252856038326879854286183861505504026924802071762598101
        );                                      
        
        vk.IC[71] = Pairing.G1Point( 
            5527120684303062875758273477585625371557472788299810892088661120109773398428,
            16249116289572836236747662414401814384121738241049779894206889394328590617648
        );                                      
        
        vk.IC[72] = Pairing.G1Point( 
            16603041890787369948592930965450807559256556705007045940875574844368935027422,
            14757707838202195149118183200754006759468055197550911766603058323703214275997
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[72] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
