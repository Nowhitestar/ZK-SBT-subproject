const hre = require("hardhat");
var fs = require('fs');

String.prototype.replaceAll = function (FindText, RepText) {
    regExp = new RegExp(FindText, "g");
    return this.replace(regExp, RepText);
};
var text = fs.readFileSync("build/verify/verify_js/call.txt", 'utf-8').replaceAll("\\[","").replaceAll("\\]","").replaceAll("\"","").replaceAll("\\s+","");
var calldata = text.split(',');

/** Collect an airdrop by proving a proof that user is over 18 yo */
async function main() {

    let singers = await hre.ethers.getSigners();
    let collector = singers[1];
    
    let PRIVATAIDROP_ADDR = "0x6771771780D10706482Be60DB4993B2DdcFB75D9"; // to add

    // A[2] B[[2][2]] C[2] represent the proof
    let a = [calldata[0], calldata[1]]
    let b = [[calldata[2], calldata[3]],[calldata[4], calldata[5]]]
    let c = [calldata[6], calldata[7]]
    // input[72] represents the public input of the circuit
    let input = calldata.slice(8,) 
    let tokenID = "1"; // to add

    let privateOver18Aidrop = await hre.ethers.getContractAt("PrivateOver18Airdrop", PRIVATAIDROP_ADDR)
    await privateOver18Aidrop.connect(collector).collectAirdrop(a, b, c, input, tokenID);
    console.log(`Proof verified`)


}

main().then(() => process.exit(0))
    .catch(e => {
        console.error(e);
        process.exit(-1);
    })




    
    

