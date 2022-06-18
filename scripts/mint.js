// Mint a setofNFT to the privateAidrop contract
const hre = require("hardhat");
const ethers = require('ethers');
const inputdata = require("../build/verify/verify_js/input.json");

async function main() {

    let singers = await hre.ethers.getSigners();
    let collector = singers[1].address;

    // fetch signature data from input.json
    let sigR8x = inputdata.challengeSignatureR8x
    let sigR8y = inputdata.challengeSignatureR8y
    let sigS = inputdata.challengeSignatureS
    let soulminter_ADDR = "0xF9Dd3738E8CEae80bC534313a72D8077Fc88AB1E"; // To add
    let privateSoulMinter = await hre.ethers.getContractAt("PrivateSoulMinter", soulminter_ADDR)
    let to = collector
    let metaURI = "https://bafybeibodo3cnumo76lzdf2dlatuoxtxahgowxuihwiqeyka7k2qt7eupy.ipfs.nftstorage.link/"
    let claimHashMetadata = ethers.utils.solidityKeccak256(["uint", "uint", "uint"], [sigR8x, sigR8y, sigS])
    let tx = await privateSoulMinter.mint(to, metaURI, claimHashMetadata);
    let receipt = await tx.wait();
    let tokenId = receipt.events?.filter((x) => { return x.event == "Transfer" })[0].topics[3]
    console.log(`# Private SBT minted to ${to}, with TokenID: ${tokenId}`)
}

main().then(() => process.exit(0))
    .catch(e => {
        console.error(e);
        process.exit(-1);
    })