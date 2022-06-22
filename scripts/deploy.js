const hre = require("hardhat");

/**
 * Deploys a test set of contracts: PrivateSoulMinter, PrivateAirdrop, verifier
 */
async function main() {

    // Deploy Private Soul Minter contract
    let PrivateSoulMinterContract = await hre.ethers.getContractFactory("PrivateSoulMinter")
    let privateSoulMinter = await PrivateSoulMinterContract.deploy()
    console.log(`Soul Minter address: ${privateSoulMinter.address}`)

    // Deploy Verifier contract
    let VerifierContract = await hre.ethers.getContractFactory("Verifier")
    let verifier = await VerifierContract.deploy()
    console.log(`Verifier contract address: ${verifier.address}`)
    let PrivateAirdropContract = await hre.ethers.getContractFactory("PrivateAirdrop")
    let privateAidrop = await PrivateAirdropContract.deploy(verifier.address, privateSoulMinter.address)
    console.log(`PrivateAirdrop contract address: ${privateAidrop.address}`)
}

main()
    .then(() => process.exit(0))
    .catch(e => {
        console.error(e);
        process.exit(1);
    })