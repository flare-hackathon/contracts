import { ethers } from "ethers";
import contrats from "../deployedContracts.json";
import roleAbi from "../artifacts/contracts/roleManager.sol/CurateAIRoleManager.json";
import { CONTRACT } from "../deploy/constants";

const RPC_URL = CONTRACT.PROVIDED_URL;
const PRIVATE_KEY = CONTRACT.PRIVATE_KEY;
const CONTRACT_ADDRESS = contrats.role;

async function callContract(recipientAddress: string) {
  try {
    const provider = new ethers.JsonRpcProvider(RPC_URL);
    const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

    const contract = new ethers.Contract(CONTRACT_ADDRESS, roleAbi.abi, wallet);

    console.log("Sending transaction...");
    const tx = await contract.assignModerator(recipientAddress);

    const receipt = await tx.wait();
    console.log(`Transaction successful! Tx Hash: ${receipt.hash}`);
  } catch (error: any) {
    console.error("Error interacting with contract:", error.message);
  }
}

callContract("0x875a7758e0F8529e9090B85A81Fe4fcC1339020d");
