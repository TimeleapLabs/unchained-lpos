const { expect } = require("chai");
const { ethers } = require("hardhat");
const { randomBytes } = require("crypto");

const zipIndex = (arr) => arr.map((item, i) => [item, i]);

const EIP712_TYPES = {
  EIP712Domain: [
    { name: "name", type: "string" },
    { name: "version", type: "string" },
    { name: "chainId", type: "uint256" },
    { name: "verifyingContract", type: "address" },
  ],
  EIP712Transfer: [
    { name: "from", type: "address" },
    { name: "to", type: "address" },
    { name: "amount", type: "uint256" },
    { name: "nonces", type: "uint256[]" },
  ],
  EIP712Slash: [
    { name: "accused", type: "address" },
    { name: "accuser", type: "address" },
    { name: "amount", type: "uint256" },
    { name: "incident", type: "bytes32" },
  ],
  EIP712SlashKey: [
    { name: "accused", type: "address" },
    { name: "amount", type: "uint256" },
    { name: "incident", type: "bytes32" },
  ],
  EIP712SetParams: [
    { name: "requester", type: "address" },
    { name: "token", type: "address" },
    { name: "nft", type: "address" },
    { name: "threshold", type: "uint256" },
    { name: "expiration", type: "uint256" },
    { name: "collector", type: "address" },
    { name: "nonce", type: "uint256" },
  ],
  EIP712SetSigner: [
    { name: "staker", type: "address" },
    { name: "signer", type: "address" },
  ],
};

const signEip712 = async (signer, domain, types, message) => {
  const signature = await signer.signTypedData(domain, types, message);
  return ethers.Signature.from(signature);
};

describe("Staking", function () {
  let staking, token, nft;
  let owner, user1, user2, user3, user4;
  let stakingAddr, tokenAddr, nftAddr;
  let user1bls, user2bls, user3bls, user4bls;
  let eip712domain;

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
      "Unchained",
      "1"
    );

    stakingAddr = await staking.getAddress();

    eip712domain = {
      name: "Unchained",
      version: "1",
      chainId: await staking.getChainId(),
      verifyingContract: stakingAddr,
    };

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

  it("should report the correct consensus threshold", async function () {
    expect(await staking.getConsensusThreshold()).to.equal(51);
  });

  it("should report the correct total voting power", async function () {
    // Stake tokens for each user
    for (const user of [user1, user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), [], false);
    }

    expect(await staking.getTotalVotingPower()).to.equal(
      ethers.parseUnits("2000")
    );
  });

  it("should report if a staker is a consumer", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), [], true);
    expect(await staking.isConsumer(user1.address)).to.equal(true);
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

  it("allows extending the stake duration", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), [1], true);
    const preExtendStake = await staking["stakeOf(address)"](user1.address);

    // Increase stake duration
    await staking.connect(user1).extend(60 * 60 * 24 * 7);
    const postExtendStake = await staking["stakeOf(address)"](user1.address);

    expect(postExtendStake.unlock).to.equal(
      preExtendStake.unlock + 60n * 60n * 24n * 7n
    );
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

  it("rejects recovering the stake token", async function () {
    await staking.connect(user1).stake(1, ethers.parseUnits("500"), [1], true);
    await expect(
      staking.connect(owner).recoverERC20(tokenAddr, owner.address, 100)
    ).to.be.revertedWithCustomError(staking, "Forbidden()");
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

  it("allows setting the contract parameters with majority consensus", async function () {
    // Stake tokens for each user
    for (const user of [user1, user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), [], false);
    }

    // Sign EIP712 message for SetParams
    const messages = [];
    const signatures = [];

    const params = {
      token: tokenAddr,
      nft: nftAddr,
      threshold: 60,
      expiration: 60 * 60 * 24 * 7,
      collector: owner.address,
      nonce: 0,
    };

    for (const user of [user1, user2, user3]) {
      const message = {
        requester: user.address,
        ...params,
      };

      const signed = await signEip712(
        user,
        eip712domain,
        { EIP712SetParams: EIP712_TYPES.EIP712SetParams },
        message
      );

      messages.push(message);
      signatures.push(signed);
    }

    // Set the parameters
    await staking.connect(owner).setParams(messages, signatures);

    // Check the parameters
    const contractParams = await staking.getParams();
    expect(contractParams.token).to.equal(params.token);
    expect(contractParams.nft).to.equal(params.nft);
    expect(contractParams.threshold).to.equal(params.threshold);
    expect(contractParams.expiration).to.equal(params.expiration);
    expect(contractParams.collector).to.equal(params.collector);

    // getSetParamsData should report correct values
    const setParamsData = await staking.getSetParamsData(params);
    expect(setParamsData.voted).to.equal(ethers.parseUnits("1500"));
    expect(setParamsData.expiration).to.equal(params.expiration);

    // getHasRequestedSetParams should report correct values
    expect(
      await staking.getHasRequestedSetParams(params, user1.address)
    ).to.equal(true);
    expect(
      await staking.getHasRequestedSetParams(params, user2.address)
    ).to.equal(true);
    expect(
      await staking.getHasRequestedSetParams(params, user3.address)
    ).to.equal(true);
    expect(
      await staking.getHasRequestedSetParams(params, user4.address)
    ).to.equal(false);
  });

  it("allows slashing a user with majority conensus", async function () {
    for (const user of [user1, user2, user3]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), [], false);
    }

    await token.connect(user4).approve(stakingAddr, ethers.parseUnits("500"));
    await staking
      .connect(user4)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), [], true);

    const incident = randomBytes(32);

    // Sign EIP712 message for Slash
    const messages = [];
    const signatures = [];

    const slash = {
      accused: user4.address,
      amount: ethers.parseUnits("100"),
      incident: incident,
    };

    for (const user of [user1, user2, user3]) {
      const message = {
        accuser: user.address,
        ...slash,
      };

      const signed = await signEip712(
        user,
        eip712domain,
        { EIP712Slash: EIP712_TYPES.EIP712Slash },
        message
      );

      messages.push(message);
      signatures.push(signed);
    }

    // Slash the consumer
    await staking.connect(owner).slash(messages, signatures);

    const postSlash = await staking["stakeOf(address)"](user4.address);
    expect(postSlash.amount).to.equal(ethers.parseUnits("400"));

    // Slash data should be available

    const slashKey = {
      accused: user4.address,
      amount: ethers.parseUnits("100"),
      incident: incident,
    };

    const slashData = await staking.getSlashData(slashKey);
    expect(slashData.accused).to.equal(user4.address);
    expect(slashData.amount).to.equal(ethers.parseUnits("100"));
    expect(slashData.voted).to.equal(ethers.parseUnits("1500"));

    // getHasSlashed should report correct values
    expect(await staking.getHasSlashed(slashKey, user1.address)).to.equal(true);
    expect(await staking.getHasSlashed(slashKey, user2.address)).to.equal(true);
    expect(await staking.getHasSlashed(slashKey, user3.address)).to.equal(true);
    expect(await staking.getHasSlashed(slashKey, user4.address)).to.equal(
      false
    );
  });

  it("allows transferring tokens from a consumer using EIP712", async function () {
    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("500"));
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), [], true);

    const nonces = [0];
    const amount = ethers.parseUnits("100");

    // Sign EIP712 message for Transfer

    const transfer = {
      from: user1.address,
      to: user2.address,
      amount: amount,
      nonces: nonces,
    };

    const signed = await signEip712(
      user1,
      eip712domain,
      { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
      transfer
    );

    const messages = [transfer];
    const signatures = [signed];

    const preTransfer = await token.balanceOf(user2.address);

    // Transfer the tokens
    await staking.connect(owner).transfer(messages, signatures);

    const postTransfer = await token.balanceOf(user2.address);
    expect(postTransfer).to.equal(preTransfer + amount);
  });

  it("rejects transferring tokens from a consumer using EIP712 with duplicated nonces", async function () {
    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("500"));
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), [], true);

    const nonces = [0];
    const amount = ethers.parseUnits("100");

    // Sign EIP712 message for Transfer

    const transfer = {
      from: user1.address,
      to: user2.address,
      amount: amount,
      nonces: nonces,
    };

    const signed = await signEip712(
      user1,
      eip712domain,
      { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
      transfer
    );

    const messages = [transfer];
    const signatures = [signed];

    // Transfer the tokens
    await staking.connect(owner).transfer(messages, signatures);

    // Attempt to transfer with the same nonce
    await expect(
      staking.connect(owner).transfer(messages, signatures)
    ).to.be.revertedWithCustomError(staking, "NonceUsed(uint256,uint256)");
  });

  it("allows setting a signer for a stake holder", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), [], false);

    const signer = user2.address;

    // Sign EIP712 message for SetSigner
    const message = {
      staker: user1.address,
      signer: signer,
    };

    const firstSignature = await signEip712(
      user1,
      eip712domain,
      { EIP712SetSigner: EIP712_TYPES.EIP712SetSigner },
      message
    );

    const secondSignature = await signEip712(
      user2,
      eip712domain,
      { EIP712SetSigner: EIP712_TYPES.EIP712SetSigner },
      message
    );

    // Set the signer
    await staking
      .connect(owner)
      .setSigner(message, firstSignature, secondSignature);

    const signerToStaker = await staking.signerToStaker(signer);
    expect(signerToStaker).to.equal(user1.address);

    const stakerToSigner = await staking.stakerToSigner(user1.address);
    expect(stakerToSigner).to.equal(signer);
  });

  it("allows signing EIP712 messages with the signer address instead of staker", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), [], true);

    const signer = user2.address;

    // Sign EIP712 message for SetSigner
    const message = {
      staker: user1.address,
      signer: signer,
    };

    const firstSignature = await signEip712(
      user1,
      eip712domain,
      { EIP712SetSigner: EIP712_TYPES.EIP712SetSigner },
      message
    );

    const secondSignature = await signEip712(
      user2,
      eip712domain,
      { EIP712SetSigner: EIP712_TYPES.EIP712SetSigner },
      message
    );

    // Set the signer
    await staking
      .connect(owner)
      .setSigner(message, firstSignature, secondSignature);

    // Sign EIP712 message for Transfer

    const amount = ethers.parseUnits("100");

    const transfer = {
      from: user1.address,
      to: user3.address,
      amount: amount,
      nonces: [0],
    };

    const signed = await signEip712(
      user2,
      eip712domain,
      { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
      transfer
    );

    const messages = [transfer];
    const signatures = [signed];

    const preTransfer = await token.balanceOf(user3.address);

    // Transfer the tokens
    await staking.connect(owner).transfer(messages, signatures);

    const postTransfer = await token.balanceOf(user3.address);
    expect(postTransfer).to.equal(preTransfer + amount);
  });

  it("allows getting user stake with bls address", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), [], true);

    const user1Stake = await staking["stakeOf(bytes20)"](user1bls);
    expect(user1Stake.amount).to.equal(ethers.parseUnits("500"));
  });
});
