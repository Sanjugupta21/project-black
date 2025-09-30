const { ethers } = require("ethers");
const fs = require("fs");
require("dotenv").config();
const readline = require("readline");

const OriginNFT_ARTIFACT = require("../artifacts/contracts/OriginNFT.sol/OriginNFT.json");
const RarityTracker_ARTIFACT = require("../artifacts/contracts/RarityTracker.sol/RarityTracker.json");
const ReactiveRarityUpdater_ARTIFACT = require("../artifacts/contracts/ReactiveRarityUpdater.sol/ReactiveRarityUpdater.json");

function askQuestion(query) {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout,
    });
    return new Promise(resolve => rl.question(query, ans => {
        rl.close();
        resolve(ans);
    }))
}

async function main() {
    console.log("--- Starting Deployment ---");
    const RPC_URL = "https://lasna-rpc.rnk.dev/";
    const provider = new ethers.JsonRpcProvider(RPC_URL);
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

    console.log("Deploying contracts with the account:", wallet.address);
    const balanceWei = await provider.getBalance(wallet.address);
    console.log("Account balance:", ethers.formatEther(balanceWei));

    const BASE_TOKEN_URI = "YOUR_IPFS_METADATA_FOLDER_URL/";
    const REACTIVE_SERVICE_ADDRESS = "0x0000000000000000000000000000000000fffFfF";

    console.log("\nStep 1: Deploying Contracts...");

    const OriginNFT_FACTORY = new ethers.ContractFactory(OriginNFT_ARTIFACT.abi, OriginNFT_ARTIFACT.bytecode, wallet);
    const originNFT = await OriginNFT_FACTORY.deploy("Rarity NFT", "RNFT", BASE_TOKEN_URI);
    await originNFT.waitForDeployment();
    console.log(`✅ OriginNFT (Origin) deployed to: ${originNFT.target}`);

    const RarityTracker_FACTORY = new ethers.ContractFactory(RarityTracker_ARTIFACT.abi, RarityTracker_ARTIFACT.bytecode, wallet);
    const rarityTracker = await RarityTracker_FACTORY.deploy();
    await rarityTracker.waitForDeployment();
    console.log(`✅ RarityTracker (Destination) deployed to: ${rarityTracker.target}`);

    const ReactiveRarityUpdater_FACTORY = new ethers.ContractFactory(ReactiveRarityUpdater_ARTIFACT.abi, ReactiveRarityUpdater_ARTIFACT.bytecode, wallet);
    const reactiveRarityUpdater = await ReactiveRarityUpdater_FACTORY.deploy(REACTIVE_SERVICE_ADDRESS, originNFT.target, rarityTracker.target);
    await reactiveRarityUpdater.waitForDeployment();
    console.log(`✅ ReactiveRarityUpdater (RSC) deployed to: ${reactiveRarityUpdater.target}`);

    console.log("\n--- DEPLOYMENT COMPLETE ---");
    
    console.log("\nStep 2: Funding the RSC...");
    console.log(`\nACTION REQUIRED: Please send 0.2 REACT to the RSC address: ${reactiveRarityUpdater.target}`);
    await askQuestion("Press Enter here after you have sent the funds...");
    console.log("Funds received. Continuing with configuration...");

    console.log("\nStep 3: Configuring Contracts...");
    
    const rarityTrackerContract = new ethers.Contract(rarityTracker.target, RarityTracker_ARTIFACT.abi, wallet);
    const reactiveRarityUpdaterContract = new ethers.Contract(reactiveRarityUpdater.target, ReactiveRarityUpdater_ARTIFACT.abi, wallet);
    
    const tx1 = await rarityTrackerContract.setAuthorizedRscAddress(reactiveRarityUpdater.target);
    await tx1.wait();
    console.log(` -> RarityTracker authorized RSC: ${reactiveRarityUpdater.target}`);
    
    const tx2 = await reactiveRarityUpdaterContract.subscribeToMintEvents();
    await tx2.wait();
    console.log(" -> Subscription to mint events created successfully!");

    console.log("\n🎉 --- HACKATHON SUBMISSION READY --- 🎉");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

