import { ethers } from "ethers";
import roleManagerContractData from "./artifacts/CurateAIRoleManager.json";
import tokenContractData from "./artifacts/CurateAIToken.json";
import postContractData from "./artifacts/CurateAIPost.json";
import voteContractData from "./artifacts/CurateAIVote.json";
import settlementContractData from "./artifacts/CurateAISettlement.json";
import { CONTRACT } from "./constants";
import { writeToFile } from "./utils/writeContract";
import dotenv from "dotenv";
dotenv.config();

export const deployContract = async () => {
  const provider = new ethers.JsonRpcProvider(CONTRACT.PROVIDED_URL);
  const wallet = new ethers.Wallet(CONTRACT.PRIVATE_KEY, provider);
  const moderator = process.env.MODERATOR_ADDRESS;

  console.log("Deploying contracts...");

  // Step 1: Deploy role manager contract
  console.log("Deploying role manger contract...");
  const roleManagerFactory = new ethers.ContractFactory(
    roleManagerContractData.abi,
    roleManagerContractData.bytecode,
    wallet
  );
  const roleManagerContract = await roleManagerFactory.deploy();
  const roleManagerAddress = await roleManagerContract.getAddress();
  await roleManagerContract.waitForDeployment();
  console.log("Deployed role manager contract:", roleManagerAddress);

  // Step 2: Deploy token contract
  console.log("Deploying token contract...");
  const tokenFactory = new ethers.ContractFactory(
    tokenContractData.abi,
    tokenContractData.bytecode,
    wallet
  );
  const tokenContract = await tokenFactory.deploy(roleManagerAddress);
  const tokenContractAddress = await tokenContract.getAddress();
  await tokenContract.waitForDeployment();

  console.log("Deployed token contract: ", tokenContractAddress);

  // Step 3: Deploy Post contract
  console.log("Deploying post contract...");
  const postFactory = new ethers.ContractFactory(
    postContractData.abi,
    postContractData.bytecode,
    wallet
  );
  const postContract = await postFactory.deploy(roleManagerAddress);
  const postContractAddress = await postContract.getAddress();
  await postContract.waitForDeployment();

  console.log("Deployed post contract: ", postContractAddress);

  // Step 4: Deploy Vote contract
  console.log("Deploying vote contract...");
  const voteFactory = new ethers.ContractFactory(
    voteContractData.abi,
    voteContractData.bytecode,
    wallet
  );
  const voteContract = await voteFactory.deploy(
    tokenContractAddress,
    roleManagerAddress,
    postContractAddress
  );
  const voteContractAddress = await voteContract.getAddress();
  await voteContract.waitForDeployment();
  console.log("Deployed vote contract:", voteContractAddress);

  // Step 5: Deploy Settlement contract
  console.log("Deploying settlement contract...");
  const settleFactory = new ethers.ContractFactory(
    settlementContractData.abi,
    settlementContractData.bytecode,
    wallet
  );
  const settleContract = await settleFactory.deploy(
    tokenContractAddress,
    voteContractAddress,
    roleManagerAddress
  );
  const settleContractAddress = await settleContract.getAddress();
  await settleContract.waitForDeployment();
  console.log("Deployed settlement contract: ", settleContractAddress);

  // Step 6: Assign roles
  console.log("Adding settlement contract and vote contract role");
  //@ts-ignore
  await roleManagerContract.setSettlementAndVotingContract(
    settleContractAddress,
    voteContractAddress
  );
  console.log("Added settlement role to token contract");

  // Step 7: Add moderator to create curators
  console.log("Adding moderator");
  //@ts-ignore
  await roleManagerContract.assignModerator(moderator);
  console.log("Added moderator successfully");

  // Step 8: Write contract addresses to a file
  console.log("Writing to deployment file...");
  writeToFile("./deployedContracts.json", {
    role: roleManagerAddress,
    token: tokenContractAddress,
    post: postContractAddress,
    vote: voteContractAddress,
    settle: settleContractAddress,
  });

  console.log("Deployment successful!");
};

deployContract();
