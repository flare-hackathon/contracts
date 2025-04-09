import { ethers } from "ethers";
import contrats from "../deployedContracts.json";
import tokenAbi from "../artifacts/contracts/token.sol/CurateAIToken.json";
import { CONTRACT } from "../deploy/constants";

const RPC_URL = CONTRACT.PROVIDED_URL;
const PRIVATE_KEY = CONTRACT.PRIVATE_KEY;
const CONTRACT_ADDRESS = contrats.token;

async function callContract(recipientAddress: string, amount: number) {
  try {
    const provider = new ethers.JsonRpcProvider(RPC_URL);
    const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

    const contract = new ethers.Contract(
      CONTRACT_ADDRESS,
      tokenAbi.abi,
      wallet
    );

    console.log("Sending transaction...");
    const tx = await contract.transfer(recipientAddress, BigInt(amount));

    const receipt = await tx.wait();
    console.log(`Transaction successful! Tx Hash: ${receipt.hash}`);
  } catch (error: any) {
    console.error("Error interacting with contract:", error.message);
  }
}

callContract("0x1f2f6f7952550D4388f9A3fd91A8CdcFbC439978", 20000);
