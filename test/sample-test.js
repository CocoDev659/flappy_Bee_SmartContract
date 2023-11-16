const { expect } = require("chai");

describe("StakingBEET", function () {
  let stakingBEET;
  let owner;
  let user1;
  let user2;

  beforeEach(async function () {
    // Deploy the contract and get contract instances
    const StakingBEET = await ethers.getContractFactory("StakingBEET");
    stakingBEET = await StakingBEET.deploy();
    await stakingBEET.deployed();

    // Get signers for different addresses
    [owner, user1, user2] = await ethers.getSigners();
  });

  it("Should deploy the contract correctly", async function () {
    expect(await stakingBEET.owner()).to.equal(owner.address);
    expect(await stakingBEET.rewardPercentPerYear()).to.equal(12);
    // Add more assertions as needed
  });

  it("Should allow users to stake tokens", async function () {
    const amountToStake = ethers.utils.parseEther("10");

    // User1 stakes tokens
    await stakingBEET.connect(user1).stake(amountToStake);

    // Check the staked amount for User1
    const user1StakedAmount = await stakingBEET.getStakedAmount(user1.address);
    expect(user1StakedAmount).to.equal(amountToStake);

    // Add more assertions as needed
  });

  it("Should allow users to unstake tokens after lock period", async function () {
    const amountToStake = ethers.utils.parseEther("10");
    const lockPeriod = 16; // Lock period in days

    // User1 stakes tokens
    await stakingBEET.connect(user1).stake(amountToStake);

    // Advance time by lock period
    await network.provider.send("evm_increaseTime", [
      lockPeriod * 24 * 60 * 60,
    ]);
    await network.provider.send("evm_mine");

    // User1 unstakes tokens
    await stakingBEET.connect(user1).unstake(amountToStake);

    // Check the unstaked tokens for User1
    const unstakedTokens = await stakingBEET.getUnstakedTokens(user1.address);
    expect(unstakedTokens.length).to.equal(1);
    expect(unstakedTokens[0].amount).to.equal(amountToStake);

    // Add more assertions as needed
  });

  // Add more test cases as needed
});
