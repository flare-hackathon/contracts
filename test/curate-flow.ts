import { expect } from "chai";
import { ethers } from "hardhat";
import {
  CurateAIToken,
  CurateAISettlement,
  CurateAIRoleManager,
  CurateAIPost,
  CurateAIVote,
} from "../typechain-types";
import keccak256 from "keccak256";

describe("ContentMediaVoting", function () {
  let contentMediaToken: CurateAIToken;
  let contentMediaSettlement: CurateAISettlement;
  let curateAIRole: CurateAIRoleManager;
  let curateAIPost: CurateAIPost;
  let curateAIVote: CurateAIVote;
  let owner: any;
  let account1: any;
  let account2: any;
  let account3: any;
  let moderator1: any;

  const CURATOR_ROLE = "CURATOR_ROLE";
  const MODERATOR_ROLE = "MODERATOR_ROLE";

  const DAILY_MINT_AMOUNT = 100_000;

  before(async function () {
    [owner, account1, account2, account3, moderator1] =
      await ethers.getSigners();

    const CurateAIRoleManagerFactory = await ethers.getContractFactory(
      "CurateAIRoleManager"
    );
    curateAIRole =
      (await CurateAIRoleManagerFactory.deploy()) as CurateAIRoleManager;

    const ContentMediaTokenFactory = await ethers.getContractFactory(
      "CurateAIToken"
    );
    contentMediaToken = (await ContentMediaTokenFactory.deploy(
      await curateAIRole.getAddress()
    )) as CurateAIToken;

    const CurateAIPostFactory = await ethers.getContractFactory("CurateAIPost");
    curateAIPost = (await CurateAIPostFactory.deploy(
      await curateAIRole.getAddress()
    )) as CurateAIPost;

    const CurateAIVoteFactory = await ethers.getContractFactory("CurateAIVote");
    curateAIVote = (await CurateAIVoteFactory.deploy(
      await contentMediaToken.getAddress(),
      await curateAIRole.getAddress(),
      await curateAIPost.getAddress()
    )) as CurateAIVote;

    const ContentMediaSettlementFactory = await ethers.getContractFactory(
      "CurateAISettlement"
    );
    contentMediaSettlement = (await ContentMediaSettlementFactory.deploy(
      contentMediaToken.getAddress(),
      curateAIVote.getAddress(),
      curateAIRole.getAddress()
    )) as CurateAISettlement;

    await curateAIRole.setSettlementContract(
      await contentMediaSettlement.getAddress()
    );
    await curateAIRole.assignModerator(moderator1);
    await curateAIRole
      .connect(moderator1)
      .assignCurator(await curateAIVote.getAddress());
  });

  describe("Add moderators", function () {
    it("Should add moderators in role manager contract", async function () {
      expect(
        await curateAIRole.hasRole(keccak256(MODERATOR_ROLE), moderator1)
      ).to.equal(true);
    });
  });

  describe("Add curators", function () {
    it("Should add curators in role manager contract", async function () {
      await curateAIRole.connect(moderator1).assignCurator(account1);
      await curateAIRole.connect(moderator1).assignCurator(account2);
      await curateAIRole.connect(moderator1).assignCurator(account3);
      await curateAIRole.connect(moderator1).assignCurator(owner);
      expect(
        await curateAIRole.hasRole(keccak256(CURATOR_ROLE), account1)
      ).to.equal(true);
    });
  });

  describe("Post Creation", function () {
    it("Should create a post and emit PostCreated event", async function () {
      const contentHash = "QmTestHash";
      const tags = "blockchain,AI";

      await expect(curateAIPost.createPost(contentHash, tags))
        .to.emit(curateAIPost, "PostCreated")
        .withArgs(1, owner.address, contentHash, tags);
    });
  });

  describe("Multiple Post Voting", function () {
    it("Should create 3 posts by 3 different accounts and vote on them", async function () {
      await curateAIPost.connect(account1).createPost("QmPost1", "tag1");
      await curateAIPost.connect(account2).createPost("QmPost2", "tag2");
      await curateAIPost.connect(account3).createPost("QmPost3", "tag3");

      const vote1 = 500000;
      const vote2 = 49999;
      const vote3 = 9;

      await curateAIVote.vote(2, vote1); // 1 post is already in above tests so the index is 2
      await curateAIVote.vote(3, vote2);
      await curateAIVote.vote(4, vote3);

      expect(await curateAIPost.getPostScore(2)).to.equal(vote1);
      expect(await curateAIPost.getPostScore(3)).to.equal(vote2);
      expect(await curateAIPost.getPostScore(4)).to.equal(vote3);
    });
  });

  describe("Token Claiming", function () {
    it("Should allow a poster to claim their earned tokens", async function () {
      const currentDay = await contentMediaSettlement.getCurrentDay();

      // Travel time by 1 day as we can only settle after a day
      await ethers.provider.send("evm_increaseTime", [86400]);
      await ethers.provider.send("evm_mine", []);

      await contentMediaSettlement.settleDay(currentDay);

      await contentMediaSettlement.connect(account1).claimRewards();
      await contentMediaSettlement.connect(account2).claimRewards();

      console.log(
        await contentMediaToken.balanceOf(account1.address),
        await contentMediaToken.balanceOf(account2.address),
        "after claiming"
      );

      expect(
        await contentMediaToken.balanceOf(account1.address)
      ).to.be.greaterThan(0);

      expect(
        (await contentMediaToken.balanceOf(account1.address)) +
          (await contentMediaToken.balanceOf(account2.address)) +
          (await contentMediaToken.balanceOf(account3.address))
      ).to.be.lessThan(DAILY_MINT_AMOUNT);
    });
  });

  describe("Multi-Day Voting and Claiming", function () {
    it("Should allow voting on multiple days and claim rewards correctly", async function () {
      const currentDay2 = await contentMediaSettlement.getCurrentDay();

      const claimable_day_1_account_3 =
        await contentMediaSettlement.getClaimableAmount(account3.address);

      await curateAIVote.vote(4, 1000);
      await curateAIVote.vote(3, 1000);

      // This is day 2
      await ethers.provider.send("evm_increaseTime", [86400]);
      await ethers.provider.send("evm_mine", []);

      await contentMediaSettlement.settleDay(currentDay2);

      const claimable_day_2_account_3 =
        await contentMediaSettlement.getClaimableAmount(account3.address);

      const claimable_day_2_account_2 =
        await contentMediaSettlement.getClaimableAmount(account2.address);

      await contentMediaSettlement.connect(account3).claimRewards();

      // Day 3 starts
      await ethers.provider.send("evm_increaseTime", [86400]);
      await ethers.provider.send("evm_mine", []);
      const claimable_day_3_account_3 =
        await contentMediaSettlement.getClaimableAmount(account3.address);

      console.log(
        "Claimable Amound: Day 1, account 3: ",
        claimable_day_1_account_3
      );
      console.log(
        "Claimable Amound: Day 2, account 3: ",
        claimable_day_2_account_3
      );
      console.log(
        "Claimable Amound: Day 2, account 2: ",
        claimable_day_2_account_2
      );
    });
  });
});
