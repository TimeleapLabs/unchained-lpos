const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UnchainedStaking", function () {
  let staking, token, nft;
  let owner, user1;
  let stakingAddr, tokenAddr, nftAddr;

  // FIXME
  beforeEach(async function () {
    [owner, user1] = await ethers.getSigners();

    // Deploy Mock ERC20 token
    const Token = await ethers.getContractFactory("DKenshi");
    token = await Token.connect(user1).deploy();

    // Deploy Mock ERC721 NFT
    const NFT = await ethers.getContractFactory("DKatana");
    nft = await NFT.connect(user1).deploy();

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

    // Approve Staking contract to spend tokens and NFT
    await token.connect(user1).approve(stakingAddr, ethers.parseEther("1000"));
    await nft.connect(user1).setApprovalForAll(stakingAddr, true);
  });

  it("allows users to stake tokens and NFTs", async function () {
    await expect(
      staking
        .connect(user1)
        .stake(60 * 60 * 24, ethers.parseEther("500"), [1], true)
    ).to.emit(staking, "Staked");

    // Check balances and ownership
    expect(await token.balanceOf(stakingAddr)).to.equal(
      ethers.parseEther("500")
    );
    expect(await nft.ownerOf(1)).to.equal(stakingAddr);
  });

  it("allows users to unstake after lock period", async function () {
    await staking.connect(user1).stake(1, ethers.parseEther("500"), [1], true);

    // Increase time to surpass the stake duration
    await ethers.provider.send("evm_increaseTime", [2]);
    await ethers.provider.send("evm_mine");

    await expect(staking.connect(user1).unstake()).to.emit(staking, "UnStaked");

    // Check balances and ownership
    expect(await token.balanceOf(user1.address)).to.equal(
      ethers.parseEther("10000000000")
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
      staking.connect(user1).stake(0, ethers.parseEther("500"), [1], true)
    ).to.be.revertedWithCustomError(staking, "DurationZero()");
  });

  it("rejects staking when already staked without unstaking", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseEther("100"), [1], true);
    await expect(
      staking
        .connect(user1)
        .stake(60 * 60 * 24, ethers.parseEther("100"), [2], true)
    ).to.be.revertedWithCustomError(staking, "AlreadyStaked()");
  });

  it("rejects unstaking before duration expires", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseEther("500"), [1], true);

    // Attempt to unstake immediately
    await expect(
      staking.connect(user1).unstake()
    ).to.be.revertedWithCustomError(staking, "NotUnlocked()");
  });

  it("allows increasing the stake", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseEther("500"), [1], true);

    // Increase stake
    await staking.connect(user1).increaseStake(ethers.parseEther("500"), [2]);
    const postIncreaseStake = await staking["stakeOf(address)"](user1.address);

    expect(postIncreaseStake.amount).to.equal(ethers.parseEther("1000"));
    expect(postIncreaseStake.nftIds.length).to.equal(2);
  });
});
