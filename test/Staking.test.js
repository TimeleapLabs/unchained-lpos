const { expect } = require("chai");
const { ethers } = require("hardhat");
const { randomBytes } = require("crypto");

const zipIndex = (arr) => arr.map((item, i) => [item, i]);

describe("Staking", function () {
  let staking, token, nft;
  let owner, user1, user2, user3, user4;
  let stakingAddr, tokenAddr, nftAddr;
  let user1bls, user2bls, user3bls, user4bls;

  beforeEach(async function () {
    [owner, user1, user2, user3, user4] = await ethers.getSigners();

    // Deploy Mock ERC20 token
    const Token = await ethers.getContractFactory("DKenshi");
    token = await Token.deploy();

    // Deploy Mock ERC721 NFT
    const NFT = await ethers.getContractFactory("DKatana");
    nft = await NFT.deploy();

    // Mint NFTs
    await nft.mint(0, 100);

    tokenAddr = await token.getAddress();
    nftAddr = await nft.getAddress();

    // Deploy the Staking contract
    const Staking = await ethers.getContractFactory("UnchainedStaking");
    staking = await Staking.deploy(
      tokenAddr,
      nftAddr,
      10,
      owner.address,
      "UnchainedStaking",
      "1"
    );

    stakingAddr = await staking.getAddress();

    // Send tokens and NFTs from owner to users
    for (const [user, userIndex] of zipIndex([user1, user2, user3, user4])) {
      await token.transfer(user.address, ethers.parseUnits("100000"));
      await nft.connect(owner).setApprovalForAll(user.address, true);
      // transfer NFTs to user
      for (let i = 0; i < 10; i++) {
        await nft
          .connect(owner)
          .safeTransferFrom(owner.address, user.address, i + userIndex * 10);
      }
    }

    // Approve Staking contract to spend tokens and NFT
    await token
      .connect(user1)
      .approve(stakingAddr, ethers.parseUnits("100000"));

    await nft.connect(user1).setApprovalForAll(stakingAddr, true);

    // Generate BLS addresses for users (Buffer[20])
    user1bls = randomBytes(20);
    user2bls = randomBytes(20);
    user3bls = randomBytes(20);
    user4bls = randomBytes(20);

    // Set BLS addresses for users
    await staking.connect(user1).setBlsAddress(user1bls);
    await staking.connect(user2).setBlsAddress(user2bls);
    await staking.connect(user3).setBlsAddress(user3bls);
    await staking.connect(user4).setBlsAddress(user4bls);
  });

  it("allows users to stake tokens and NFTs", async function () {
    await expect(
      staking
        .connect(user1)
        .stake(60 * 60 * 24, ethers.parseUnits("500"), [1], true)
    ).to.emit(staking, "Staked");

    // Check balances and ownership
    expect(await token.balanceOf(stakingAddr)).to.equal(
      ethers.parseUnits("500")
    );
    expect(await nft.ownerOf(1)).to.equal(stakingAddr);
  });

  it("allows users to unstake after lock period", async function () {
    await staking.connect(user1).stake(1, ethers.parseUnits("500"), [1], true);

    // Increase time to surpass the stake duration
    await ethers.provider.send("evm_increaseTime", [2]);
    await ethers.provider.send("evm_mine");

    await expect(staking.connect(user1).unstake()).to.emit(staking, "UnStaked");

    // Check balances and ownership
    expect(await token.balanceOf(user1.address)).to.equal(
      ethers.parseUnits("100000")
    );
    expect(await nft.ownerOf(1)).to.equal(user1.address);
  });

  it("rejects staking with zero amount", async function () {
    await expect(
      staking.connect(user1).stake(60 * 60 * 24, 0, [], true)
    ).to.be.revertedWithCustomError(staking, "AmountZero()");
  });

  it("rejects staking with zero duration", async function () {
    await expect(
      staking.connect(user1).stake(0, ethers.parseUnits("500"), [1], true)
    ).to.be.revertedWithCustomError(staking, "DurationZero()");
  });

  it("rejects staking when already staked without unstaking", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("100"), [1], true);
    await expect(
      staking
        .connect(user1)
        .stake(60 * 60 * 24, ethers.parseUnits("100"), [2], true)
    ).to.be.revertedWithCustomError(staking, "AlreadyStaked()");
  });

  it("rejects unstaking before duration expires", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), [1], true);

    // Attempt to unstake immediately
    await expect(
      staking.connect(user1).unstake()
    ).to.be.revertedWithCustomError(staking, "NotUnlocked()");
  });

  it("allows increasing the stake", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), [1], true);

    // Increase stake
    await staking.connect(user1).increaseStake(ethers.parseUnits("500"), [2]);
    const postIncreaseStake = await staking["stakeOf(address)"](user1.address);

    expect(postIncreaseStake.amount).to.equal(ethers.parseUnits("1000"));
    expect(postIncreaseStake.nftIds.length).to.equal(2);
  });
});