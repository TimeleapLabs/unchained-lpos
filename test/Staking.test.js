const { expect } = require("chai");
const { ethers } = require("hardhat");
const { randomBytes } = require("crypto");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

const zipIndex = (arr) => arr.map((item, i) => [item, i]);

// TODO: Add unit tests for duplicate incidents
// TODO: Add unit tests for duplicate set param requests & nonces

const EIP712_TYPES = {
  EIP712Domain: [
    { name: "name", type: "string" },
    { name: "version", type: "string" },
    { name: "chainId", type: "uint256" },
    { name: "verifyingContract", type: "address" },
  ],
  EIP712Transfer: [
    { name: "signer", type: "address" },
    { name: "from", type: "address" },
    { name: "to", type: "address" },
    { name: "amount", type: "uint256" },
    { name: "nftIds", type: "uint256[]" },
    { name: "nonces", type: "uint256[]" },
  ],
  EIP712TransferKey: [
    { name: "from", type: "address" },
    { name: "to", type: "address" },
    { name: "amount", type: "uint256" },
    { name: "nftIds", type: "uint256[]" },
    { name: "nonces", type: "uint256[]" },
  ],
  EIP712SetParams: [
    { name: "requester", type: "address" },
    { name: "token", type: "address" },
    { name: "nft", type: "address" },
    { name: "threshold", type: "uint256" },
    { name: "expiration", type: "uint256" },
    { name: "nonce", type: "uint256" },
  ],
  EIP712SetParamsKey: [
    { name: "token", type: "address" },
    { name: "nft", type: "address" },
    { name: "threshold", type: "uint256" },
    { name: "expiration", type: "uint256" },
    { name: "nonce", type: "uint256" },
  ],
  EIP712SetSigner: [
    { name: "staker", type: "address" },
    { name: "signer", type: "address" },
  ],
  EIP712SetNftPrice: [
    { name: "requester", type: "address" },
    { name: "nftId", type: "uint256" },
    { name: "price", type: "uint256" },
    { name: "nonce", type: "uint256" },
  ],
  EIP712SetNftPriceKey: [
    { name: "nftId", type: "uint256" },
    { name: "price", type: "uint256" },
    { name: "nonce", type: "uint256" },
  ],
};

const signEip712 = async (signer, domain, types, message) => {
  const signature = await signer.signTypedData(domain, types, message);
  return ethers.Signature.from(signature);
};

describe("Staking", function () {
  let staking, token, nft;
  let owner, user1, user2, user3, user4, user5;
  let stakingAddr, tokenAddr, nftAddr;
  let user1bls, user2bls, user3bls, user4bls;
  let eip712domain;

  async function deploy(consensusLock = 10) {
    [owner, user1, user2, user3, user4, user5] = await ethers.getSigners();

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
      consensusLock,
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
  }

  beforeEach(async function () {
    await deploy();
  });

  it("reports the correct consensus threshold", async function () {
    expect(await staking.getConsensusThreshold()).to.equal(51);
  });

  it("reports the correct total voting power", async function () {
    // Stake tokens for each user
    for (const user of [user1, user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
    }

    expect(await staking.getTotalVotingPower()).to.equal(
      ethers.parseUnits("2000")
    );
  });

  it("allows users to stake tokens and NFTs", async function () {
    await expect(
      staking.connect(user1).stake(60 * 60 * 24, ethers.parseUnits("500"), [1])
    ).to.emit(staking, "Staked");

    // Check balances and ownership
    expect(await token.balanceOf(stakingAddr)).to.equal(
      ethers.parseUnits("500")
    );
    expect(await nft.ownerOf(1)).to.equal(stakingAddr);
  });

  it("allows users to stake NFTs only", async function () {
    await expect(staking.connect(user1).stake(60 * 60 * 24, 0, [1])).to.emit(
      staking,
      "Staked"
    );

    // Check balances (to be zero) and ownership
    expect(await token.balanceOf(stakingAddr)).to.equal(0);
    expect(await nft.ownerOf(1)).to.equal(stakingAddr);
  });

  it("allows extending the stake duration", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), [1]);
    const preExtendStake = await staking["getStake(address)"](user1.address);

    // Increase stake duration
    await staking.connect(user1).extend(60 * 60 * 24 * 7);
    const postExtendStake = await staking["getStake(address)"](user1.address);

    expect(postExtendStake.unlock).to.equal(
      preExtendStake.unlock + 60n * 60n * 24n * 7n
    );
  });

  it("allows users to unstake after lock period", async function () {
    await staking.connect(user1).stake(1, ethers.parseUnits("500"), [1]);

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

  it("rejects unstaking with zero stake", async function () {
    await expect(
      staking.connect(user1).unstake()
    ).to.be.revertedWithCustomError(staking, "StakeZero()");
  });

  it("rejects setting setting bls address of another user", async function () {
    await expect(
      staking.connect(user1).setBlsAddress(user2bls)
    ).to.be.revertedWithCustomError(staking, "AddressInUse()");
  });

  it("rejects recovering the stake token", async function () {
    await staking.connect(user1).stake(1, ethers.parseUnits("500"), [1]);
    await expect(
      staking.connect(owner).recoverERC20(tokenAddr, owner.address, 100)
    ).to.be.revertedWithCustomError(staking, "Forbidden()");
  });

  it("allows recovering the non-stake tokens", async function () {
    await staking.connect(user1).stake(1, ethers.parseUnits("500"), [1]);

    // Deploy a mock ERC20 contract for testing
    const MockERC20 = await ethers.getContractFactory("DKenshi");
    const mockToken = await MockERC20.deploy();

    // Transfer some tokens to the staking contract
    await mockToken.transfer(stakingAddr, ethers.parseUnits("100"));

    const mockTokenAddr = await mockToken.getAddress();

    // Recover ERC20 tokens, expecting the safeTransfer function to be called
    await staking
      .connect(owner)
      .recoverERC20(mockTokenAddr, user1.address, ethers.parseUnits("100"));

    // Check if the tokens were transferred successfully
    const recipientBalance = await mockToken.balanceOf(user1.address);
    expect(recipientBalance).to.equal(ethers.parseUnits("100"));
  });

  it("rejects staking with zero amount", async function () {
    await expect(
      staking.connect(user1).stake(60 * 60 * 24, 0, [])
    ).to.be.revertedWithCustomError(staking, "AmountZero()");
  });

  it("rejects staking with zero duration", async function () {
    await expect(
      staking.connect(user1).stake(0, ethers.parseUnits("500"), [1])
    ).to.be.revertedWithCustomError(staking, "DurationZero()");
  });

  it("rejects staking when already staked without unstaking", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("100"), [1]);
    await expect(
      staking.connect(user1).stake(60 * 60 * 24, ethers.parseUnits("100"), [2])
    ).to.be.revertedWithCustomError(staking, "AlreadyStaked()");
  });

  it("rejects unstaking before duration expires", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), [1]);

    // Attempt to unstake immediately
    await expect(
      staking.connect(user1).unstake()
    ).to.be.revertedWithCustomError(staking, "NotUnlocked()");
  });

  it("allows increasing the stake", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), [1]);

    // Increase stake
    await staking.connect(user1).increaseStake(ethers.parseUnits("500"), [2]);
    const postIncreaseStake = await staking["getStake(address)"](user1.address);

    expect(postIncreaseStake.amount).to.equal(ethers.parseUnits("1000"));
    expect(postIncreaseStake.nftIds.length).to.equal(2);
  });

  it("allows increasing the stake with NFTs only", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), [1]);

    // Increase stake
    await staking.connect(user1).increaseStake(0, [2]);
    const postIncreaseStake = await staking["getStake(address)"](user1.address);

    expect(postIncreaseStake.amount).to.equal(ethers.parseUnits("500"));
    expect(postIncreaseStake.nftIds.length).to.equal(2);
  });

  it("rejects increasing the stake with zero amount", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), [1]);

    await expect(
      staking.connect(user1).increaseStake(0, [])
    ).to.be.revertedWithCustomError(staking, "AmountZero()");
  });

  it("rejects increasing non-existent stake", async function () {
    await expect(
      staking.connect(user1).increaseStake(ethers.parseUnits("500"), [1])
    ).to.be.revertedWithCustomError(staking, "StakeZero()");
  });

  it("rejects extending the stake duration with zero duration", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), [1]);

    await expect(
      staking.connect(user1).extend(0)
    ).to.be.revertedWithCustomError(staking, "DurationZero()");
  });

  it("rejects extending the duration of non-existent stake", async function () {
    await expect(
      staking.connect(user1).extend(60 * 60 * 24)
    ).to.be.revertedWithCustomError(staking, "StakeZero()");
  });

  it("rejects staking if bls address is not set", async function () {
    await expect(
      staking.connect(user5).stake(60 * 60 * 24, ethers.parseUnits("500"), [1])
    ).to.be.revertedWithCustomError(staking, "BlsNotSet()");
  });

  it("allows setting the contract parameters with majority consensus", async function () {
    // Stake tokens for each user
    for (const user of [user1, user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
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

    // getSetParamsData reports correct values
    const setParamsData = await staking.getSetParamsData(params);
    expect(setParamsData.voted).to.equal(ethers.parseUnits("1500"));
    expect(setParamsData.expiration).to.equal(params.expiration);

    // getRequestedSetParams reports correct values
    expect(await staking.getRequestedSetParams(params, user1.address)).to.equal(
      true
    );
    expect(await staking.getRequestedSetParams(params, user2.address)).to.equal(
      true
    );
    expect(await staking.getRequestedSetParams(params, user3.address)).to.equal(
      true
    );
    expect(await staking.getRequestedSetParams(params, user4.address)).to.equal(
      false
    );
  });

  it("reverts setParams if consensus lock is not reached", async function () {
    await deploy(999999);
    // Stake tokens for each user
    for (const user of [user1, user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
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
    await expect(
      staking.connect(owner).setParams(messages, signatures)
    ).to.be.revertedWithCustomError(staking, "Forbidden()");
  });

  it("reverts setParams if signature is invalid", async function () {
    // Stake tokens for each user
    for (const user of [user1, user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
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

    const message = {
      requester: user2.address,
      ...params,
    };

    const signed = await signEip712(
      user3,
      eip712domain,
      { EIP712SetParams: EIP712_TYPES.EIP712SetParams },
      message
    );

    messages.push(message);
    signatures.push(signed);

    // Set the parameters
    await expect(
      staking.connect(owner).setParams(messages, signatures)
    ).to.be.revertedWithCustomError(staking, "InvalidSignature(uint)");
  });

  it("rejects consensus setParams if signatures don't match the setParams length", async function () {
    // Stake tokens for each user
    for (const user of [user1, user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
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
    await expect(
      staking.connect(owner).setParams(messages, signatures.slice(1))
    ).to.be.revertedWithCustomError(staking, "LengthMismatch()");
  });

  it("reverts setParams signer has zero voting power", async function () {
    // Stake tokens for each user
    for (const user of [user1, user2]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
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

    const message = {
      requester: user3.address,
      ...params,
    };

    const signed = await signEip712(
      user3,
      eip712domain,
      { EIP712SetParams: EIP712_TYPES.EIP712SetParams },
      message
    );

    messages.push(message);
    signatures.push(signed);

    // Set the parameters
    await expect(
      staking.connect(owner).setParams(messages, signatures)
    ).to.be.revertedWithCustomError(staking, "VotingPowerZero(uint)");
  });

  it("reverts setParams if stake expires before vote", async function () {
    // Stake tokens for each user
    for (const user of [user1, user2]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
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

    await time.increase(60 * 60 * 24 * 364.5);
    const message = {
      requester: user2.address,
      ...params,
    };

    const signed = await signEip712(
      user2,
      eip712domain,
      { EIP712SetParams: EIP712_TYPES.EIP712SetParams },
      message
    );

    messages.push(message);
    signatures.push(signed);

    // Set the parameters
    await expect(
      staking.connect(owner).setParams(messages, signatures)
    ).to.be.revertedWithCustomError(staking, "StakeExpiresBeforeVote(uint)");
  });

  it("reverts setParams if topic expired", async function () {
    // Stake tokens for each user
    for (const user of [user1, user2]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
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

    const message = {
      requester: user2.address,
      ...params,
    };

    const signed = await signEip712(
      user2,
      eip712domain,
      { EIP712SetParams: EIP712_TYPES.EIP712SetParams },
      message
    );

    messages.push(message);
    signatures.push(signed);

    await staking.connect(owner).setParams(messages, signatures);

    //go forward in time for 2 days
    await time.increase(2 * 24 * 60 * 60);
    // Set the parameters
    await expect(
      staking.connect(owner).setParams(messages, signatures)
    ).to.be.revertedWithCustomError(staking, "TopicExpired(uint)");
  });

  it("allows signing EIP712 transfer messages with the signer address instead of staker", async function () {
    // Stake tokens for each user
    for (const user of [user1, user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
    }

    const signerForUser1 = user5;

    // Sign EIP712 message for SetSigner
    const message = {
      staker: user1.address,
      signer: signerForUser1.address,
    };

    const firstSignature = await signEip712(
      user1,
      eip712domain,
      { EIP712SetSigner: EIP712_TYPES.EIP712SetSigner },
      message
    );

    const secondSignature = await signEip712(
      signerForUser1,
      eip712domain,
      { EIP712SetSigner: EIP712_TYPES.EIP712SetSigner },
      message
    );

    // Set the signer
    await staking
      .connect(owner)
      .setSigner(message, firstSignature, secondSignature);

    // Sign EIP712 message for Transfer
    const messages = [];
    const signatures = [];

    const transfer = {
      from: user4.address,
      to: user1.address,
      nftIds: [],
      amount: ethers.parseUnits("100"),
      nonces: [0],
    };

    const signers = [
      { staker: user1, signer: signerForUser1 },
      { staker: user2, signer: user2 },
      { staker: user3, signer: user3 },
    ];

    for (const { staker, signer } of signers) {
      const message = {
        signer: staker.address,
        ...transfer,
      };

      const signed = await signEip712(
        signer,
        eip712domain,
        { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
        message
      );

      messages.push(message);
      signatures.push(signed);
    }

    // Transfer the tokens
    const preTransfer = await token.balanceOf(user1.address);
    await staking.connect(owner).transfer(messages, signatures);
    await staking.connect(owner).transfer(messages, signatures);

    // Transfer data should be available
    const slashData = await staking.getTransferData(transfer);
    expect(slashData.to).to.equal(user1.address);
    expect(slashData.amount).to.equal(ethers.parseUnits("100"));
    expect(slashData.voted).to.equal(ethers.parseUnits("1500"));
    expect(slashData.accepted).to.equal(true);

    // getRequestedTransfer reports correct values
    expect(
      await staking.getRequestedTransfer(transfer, user1.address)
    ).to.equal(true);

    expect(
      await staking.getRequestedTransfer(transfer, user2.address)
    ).to.equal(true);

    expect(
      await staking.getRequestedTransfer(transfer, user3.address)
    ).to.equal(true);

    expect(
      await staking.getRequestedTransfer(transfer, user4.address)
    ).to.equal(false);

    // Tokens should be available in the user's account
    const postTransfer = await token.balanceOf(user1.address);
    expect(postTransfer).to.equal(preTransfer + ethers.parseUnits("100"));
  });

  it("allows signing EIP712 setParam messages with the signer address instead of staker", async function () {
    // Stake tokens for each user
    for (const user of [user1, user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
    }

    const signerForUser1 = user5;

    // Sign EIP712 message for SetSigner
    const message = {
      staker: user1.address,
      signer: signerForUser1.address,
    };

    const firstSignature = await signEip712(
      user1,
      eip712domain,
      { EIP712SetSigner: EIP712_TYPES.EIP712SetSigner },
      message
    );

    const secondSignature = await signEip712(
      signerForUser1,
      eip712domain,
      { EIP712SetSigner: EIP712_TYPES.EIP712SetSigner },
      message
    );

    // Set the signer
    await staking
      .connect(owner)
      .setSigner(message, firstSignature, secondSignature);

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

    const signers = [
      { staker: user1, signer: signerForUser1 },
      { staker: user2, signer: user2 },
      { staker: user3, signer: user3 },
    ];

    for (const { staker, signer } of signers) {
      const message = {
        requester: staker.address,
        ...params,
      };

      const signed = await signEip712(
        signer,
        eip712domain,
        { EIP712SetParams: EIP712_TYPES.EIP712SetParams },
        message
      );

      messages.push(message);
      signatures.push(signed);
    }

    // Set the parameters
    await staking.connect(owner).setParams(messages, signatures);
    await staking.connect(owner).setParams(messages, signatures);

    // Check the parameters
    const contractParams = await staking.getParams();
    expect(contractParams.token).to.equal(params.token);
    expect(contractParams.nft).to.equal(params.nft);
    expect(contractParams.threshold).to.equal(params.threshold);
    expect(contractParams.expiration).to.equal(params.expiration);

    // getSetParamsData reports correct values
    const setParamsData = await staking.getSetParamsData(params);
    expect(setParamsData.voted).to.equal(ethers.parseUnits("1500"));
    expect(setParamsData.expiration).to.equal(params.expiration);

    // getRequestedSetParams reports correct values
    expect(await staking.getRequestedSetParams(params, user1.address)).to.equal(
      true
    );
    expect(await staking.getRequestedSetParams(params, user2.address)).to.equal(
      true
    );
    expect(await staking.getRequestedSetParams(params, user3.address)).to.equal(
      true
    );
    expect(await staking.getRequestedSetParams(params, user4.address)).to.equal(
      false
    );
  });

  it("allows signing EIP712 setNftPrice messages with the signer address instead of staker", async function () {
    // Stake tokens for each user
    for (const user of [user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("50"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("50"), []);
    }
    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("200"));
    await staking
      .connect(user1)
      .stake(25 * 60 * 60 * 24, ethers.parseUnits("200"), [1, 2]);

    const signerForUser1 = user5;

    // Sign EIP712 message for SetSigner
    const message = {
      staker: user1.address,
      signer: signerForUser1.address,
    };

    const firstSignature = await signEip712(
      user1,
      eip712domain,
      { EIP712SetSigner: EIP712_TYPES.EIP712SetSigner },
      message
    );

    const secondSignature = await signEip712(
      signerForUser1,
      eip712domain,
      { EIP712SetSigner: EIP712_TYPES.EIP712SetSigner },
      message
    );

    // Set the signer
    await staking
      .connect(owner)
      .setSigner(message, firstSignature, secondSignature);

    // Sign EIP712 message for setNftPrice
    const nftprices = [];
    const signatures = [];

    const nftSetPrice = {
      requester: user1.address,
      nftId: 7,
      price: ethers.parseUnits("5"),
      nonce: 0,
    };

    const signers = [
      { staker: user1, signer: signerForUser1 },
      { staker: user2, signer: user2 },
      { staker: user3, signer: user3 },
    ];

    for (const { staker, signer } of signers) {
      const nftprice = {
        signer: staker.address,
        ...nftSetPrice,
      };

      const signed = await signEip712(
        signer,
        eip712domain,
        { EIP712SetNftPrice: EIP712_TYPES.EIP712SetNftPrice },
        nftprice
      );

      nftprices.push(nftprice);
      signatures.push(signed);
    }

    await staking.connect(user1).setNftPrices(nftprices, signatures);
    await staking.connect(user1).setNftPrices(nftprices, signatures);
    const nftSetPriceKey = {
      nftId: 7,
      price: ethers.parseUnits("5"),
      nonce: 0,
    };

    // Call the getRequestedSetNftPrice function to check if the address has requested the set of NFT prices
    const hasRequested = await staking.getRequestedSetNftPrice(
      nftSetPriceKey,
      user1.address
    );
    const nftPriceInfo = await staking.getSetNftPriceData(nftSetPriceKey);
    const nftPriceResult = await staking.getPrice(7);

    expect(nftPriceInfo.price).to.equal(ethers.parseUnits("5"));
    expect(nftPriceInfo.accepted).to.equal(true);
    expect(nftPriceInfo.voted).to.equal(ethers.parseUnits("200"));

    expect(nftPriceResult).to.equal(ethers.parseUnits("5"));
    expect(hasRequested).to.equal(true);
  });

  it("rejects setting the contract parameters with duplicate signatures", async function () {
    // Stake tokens for each user
    for (const user of [user1, user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
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

    for (const user of [user1, user1, user1, user1]) {
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
    staking.connect(owner).setParams(messages, signatures);

    // Check the parameters, they shouldn't be set
    const contractParams = await staking.getParams();
    expect(contractParams.threshold).to.not.equal(params.threshold);
    expect(contractParams.expiration).to.not.equal(params.expiration);
  });

  it("allows transfering tokens from staked users by consensus", async function () {
    for (const user of [user4, user2, user3]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
    }

    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("500"));
    await staking
      .connect(user1)
      .stake(3600, ethers.parseUnits("500"), [2, 3, 1]);

    // Sign EIP712 message for Transfer
    const messages = [];
    const signatures = [];

    const transfer = {
      from: user1.address,
      to: user4.address,
      nftIds: [1],
      amount: ethers.parseUnits("100"),
      nonces: [0],
    };

    for (const user of [user4, user2, user3]) {
      const message = {
        signer: user.address,
        ...transfer,
      };

      const signed = await signEip712(
        user,
        eip712domain,
        { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
        message
      );

      messages.push(message);
      signatures.push(signed);
    }

    // Transfer the tokens
    const preTransferTo = await token.balanceOf(user4.address);
    const preTransferFrom = await staking["getStake(address)"](user1.address);
    await staking.connect(owner).transfer(messages, signatures);

    // Transfer data should be available
    const slashData = await staking.getTransferData(transfer);
    expect(slashData.to).to.equal(user4.address);
    expect(slashData.amount).to.equal(ethers.parseUnits("100"));
    expect(slashData.voted).to.equal(ethers.parseUnits("1500"));
    expect(slashData.accepted).to.equal(true);

    // getRequestedTransfer reports correct values
    expect(
      await staking.getRequestedTransfer(transfer, user4.address)
    ).to.equal(true);

    expect(
      await staking.getRequestedTransfer(transfer, user2.address)
    ).to.equal(true);

    expect(
      await staking.getRequestedTransfer(transfer, user3.address)
    ).to.equal(true);

    expect(
      await staking.getRequestedTransfer(transfer, user1.address)
    ).to.equal(false);

    // Tokens should be available in the user's account
    const postTransfer = await token.balanceOf(user4.address);
    expect(postTransfer).to.equal(preTransferTo + ethers.parseUnits("100"));

    // Should not transfer the amount
    await staking.connect(owner).transfer(messages, signatures);
    expect(slashData.accepted).to.equal(true);
    const postTransfersFrom = await staking["getStake(address)"](user1.address);
    expect(postTransfersFrom.amount).to.equal(
      preTransferFrom.amount - ethers.parseUnits("100")
    );
  });

  it("reverts transfer if stake expires before vote", async function () {
    for (const user of [user4, user2, user3]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
    }

    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("500"));
    await staking.connect(user1).stake(3600, ethers.parseUnits("500"), [1]);

    const transfer = {
      from: user1.address,
      to: user4.address,
      nftIds: [1],
      amount: ethers.parseUnits("100"),
      nonces: [0],
    };

    await time.increase(60 * 60 * 24 * 364.5);

    // Sign EIP712 message for Transfer
    const messages = [];
    const signatures = [];

    for (const user of [user4, user2, user3]) {
      const message = {
        signer: user.address,
        ...transfer,
      };

      const signed = await signEip712(
        user,
        eip712domain,
        { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
        message
      );

      messages.push(message);
      signatures.push(signed);
    }

    await expect(
      staking.connect(owner).transfer(messages, signatures)
    ).to.be.revertedWithCustomError(staking, "StakeExpiresBeforeVote(uint)");
  });

  it("reverts transfer signer has zero voting power", async function () {
    for (const user of [user4, user2, user3]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
    }

    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("500"));
    await staking.connect(user1).stake(3600, ethers.parseUnits("500"), [1]);

    const transfer = {
      from: user1.address,
      to: user4.address,
      nftIds: [1],
      amount: ethers.parseUnits("100"),
      nonces: [0],
    };

    // Sign EIP712 message for Transfer
    const messages = [];
    const signatures = [];

    const message = {
      signer: user5.address,
      ...transfer,
    };

    const signed = await signEip712(
      user5,
      eip712domain,
      { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
      message
    );

    messages.push(message);
    signatures.push(signed);

    await expect(
      staking.connect(owner).transfer(messages, signatures)
    ).to.be.revertedWithCustomError(staking, "VotingPowerZero(uint)");
  });

  it("reverts transfer if signature is invalid", async function () {
    for (const user of [user4, user2, user3]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
    }

    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("500"));
    await staking.connect(user1).stake(3600, ethers.parseUnits("500"), [1]);

    const transfer = {
      from: user1.address,
      to: user4.address,
      nftIds: [1],
      amount: ethers.parseUnits("100"),
      nonces: [0],
    };

    // Sign EIP712 message for Transfer
    const messages = [];
    const signatures = [];

    const message = {
      signer: user2.address,
      ...transfer,
    };

    const signed = await signEip712(
      user4,
      eip712domain,
      { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
      message
    );

    messages.push(message);
    signatures.push(signed);

    await expect(
      staking.connect(owner).transfer(messages, signatures)
    ).to.be.revertedWithCustomError(staking, "InvalidSignature(uint)");
  });

  it("reverts transfer from unchained with NFT's", async function () {
    for (const user of [user1, user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
    }

    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("500"));
    await staking.connect(user1).transferToUnchained(ethers.parseUnits("500"));

    // Sign EIP712 message for Transfer
    const messages = [];
    const signatures = [];

    const transfer = {
      from: stakingAddr,
      to: user4.address,
      nftIds: [1],
      amount: ethers.parseUnits("100"),
      nonces: [0],
    };

    for (const user of [user1, user2, user3]) {
      const message = {
        signer: user.address,
        ...transfer,
      };

      const signed = await signEip712(
        user,
        eip712domain,
        { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
        message
      );

      messages.push(message);
      signatures.push(signed);
    }

    // Transfer the tokens
    await expect(
      staking.connect(owner).transfer(messages, signatures)
    ).to.be.revertedWithCustomError(staking, "Forbidden()");
  });

  it("reverts transfer if topic expired", async function () {
    for (const user of [user4, user2, user3]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
    }

    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("500"));
    await staking.connect(user1).stake(3600, ethers.parseUnits("500"), [1]);

    // Sign EIP712 message for fail Transfer
    const messages = [];
    const signatures = [];

    const transfer = {
      from: user1.address,
      to: user4.address,
      nftIds: [1],
      amount: ethers.parseUnits("100"),
      nonces: [0],
    };
    const message = {
      signer: user2.address,
      ...transfer,
    };

    const signed = await signEip712(
      user2,
      eip712domain,
      { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
      message
    );

    messages.push(message);
    signatures.push(signed);

    // Transfer the tokens
    await staking.connect(owner).transfer(messages, signatures);

    //go forward in time for 2 days
    await time.increase(2 * 24 * 60 * 60);

    await expect(
      staking.connect(owner).transfer(messages, signatures)
    ).to.be.revertedWithCustomError(staking, "TopicExpired(uint)");
  });

  it("reverts transfer if consensus lock is not reached", async function () {
    await deploy(999999);
    for (const user of [user4, user2, user3]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
    }

    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("500"));
    await staking.connect(user1).stake(3600, ethers.parseUnits("500"), [1]);

    // Sign EIP712 message for Transfer
    const messages = [];
    const signatures = [];

    const transfer = {
      from: user1.address,
      to: user4.address,
      nftIds: [1],
      amount: ethers.parseUnits("100"),
      nonces: [0],
    };

    for (const user of [user4, user2, user3]) {
      const message = {
        signer: user.address,
        ...transfer,
      };

      const signed = await signEip712(
        user,
        eip712domain,
        { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
        message
      );

      messages.push(message);
      signatures.push(signed);
    }

    // Transfer the tokens
    const preTransfer = await token.balanceOf(user4.address);
    await expect(
      staking.connect(owner).transfer(messages, signatures)
    ).to.be.revertedWithCustomError(staking, "Forbidden()");
  });

  it("allows transfering tokens to Unchained", async function () {
    const preTransfer = await token.balanceOf(stakingAddr);
    await staking.connect(user1).transferToUnchained(ethers.parseUnits("500"));

    const postTransfer = await token.balanceOf(stakingAddr);
    expect(postTransfer).to.equal(preTransfer + ethers.parseUnits("500"));
  });

  it("rejects sending tokens to Unchained with no BLS address", async function () {
    await expect(
      staking.connect(user5).transferToUnchained(ethers.parseUnits("500"))
    ).to.be.revertedWithCustomError(staking, "BlsNotSet()");
  });

  it("reports the correct amount of tokens transferred to Unchained", async function () {
    await staking.connect(user1).transferToUnchained(ethers.parseUnits("500"));
    expect(await staking.getTotalLockedInUnchained()).to.equal(
      ethers.parseUnits("500")
    );
  });

  it("allows transfering tokens from the contract by consensus", async function () {
    for (const user of [user1, user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
    }

    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("500"));
    await staking.connect(user1).transferToUnchained(ethers.parseUnits("500"));

    // Sign EIP712 message for Transfer
    const messages = [];
    const signatures = [];

    const transfer = {
      from: stakingAddr,
      to: user4.address,
      nftIds: [],
      amount: ethers.parseUnits("100"),
      nonces: [0],
    };

    for (const user of [user1, user2, user3]) {
      const message = {
        signer: user.address,
        ...transfer,
      };

      const signed = await signEip712(
        user,
        eip712domain,
        { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
        message
      );

      messages.push(message);
      signatures.push(signed);
    }

    // Transfer the tokens
    const preTransfer = await token.balanceOf(user4.address);
    await staking.connect(owner).transfer(messages, signatures);

    // Transfer data should be available
    const txData = await staking.getTransferData(transfer);
    expect(txData.to).to.equal(user4.address);
    expect(txData.amount).to.equal(ethers.parseUnits("100"));
    expect(txData.voted).to.equal(ethers.parseUnits("1500"));
    expect(txData.accepted).to.equal(true);

    // getRequestedTransfer reports correct values
    expect(
      await staking.getRequestedTransfer(transfer, user1.address)
    ).to.equal(true);

    expect(
      await staking.getRequestedTransfer(transfer, user2.address)
    ).to.equal(true);

    expect(
      await staking.getRequestedTransfer(transfer, user3.address)
    ).to.equal(true);

    expect(
      await staking.getRequestedTransfer(transfer, user4.address)
    ).to.equal(false);

    // Tokens should be available in the user's account
    const postTransfer = await token.balanceOf(user4.address);
    expect(postTransfer).to.equal(preTransfer + ethers.parseUnits("100"));
  });

  it("rejects consensus transfers if signatures don't match the transfers length", async function () {
    for (const user of [user1, user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
    }

    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("500"));
    await staking.connect(user1).transferToUnchained(ethers.parseUnits("500"));

    // Sign EIP712 message for Transfer
    const messages = [];
    const signatures = [];

    const transfer = {
      from: stakingAddr,
      to: user4.address,
      nftIds: [],
      amount: ethers.parseUnits("100"),
      nonces: [0],
    };

    for (const user of [user1, user2, user3]) {
      const message = {
        signer: user.address,
        ...transfer,
      };

      const signed = await signEip712(
        user,
        eip712domain,
        { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
        message
      );

      messages.push(message);
      signatures.push(signed);
    }

    // Transfer the tokens
    expect(
      staking.connect(owner).transfer(messages, signatures.slice(1))
    ).to.be.revertedWithCustomError(staking, "LengthMismatch()");
  });

  it("rejects transfering tokens to Unchained with zero amount", async function () {
    await expect(
      staking.connect(user1).transferToUnchained(0)
    ).to.be.revertedWithCustomError(staking, "AmountZero()");
  });

  it("allows slashing a staker with transfer out", async function () {
    for (const user of [user1, user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
    }

    // Sign EIP712 message for Transfer
    const messages = [];
    const signatures = [];

    const transfer = {
      from: user4.address,
      to: user1.address,
      nftIds: [],
      amount: ethers.parseUnits("100"),
      nonces: [0],
    };

    for (const user of [user1, user2, user3]) {
      const message = {
        signer: user.address,
        ...transfer,
      };

      const signed = await signEip712(
        user,
        eip712domain,
        { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
        message
      );

      messages.push(message);
      signatures.push(signed);
    }

    // Transfer the tokens
    await staking.connect(owner).transfer(messages, signatures);
    const stake = await staking["getStake(address)"](user4.address);

    expect(stake.amount).to.equal(ethers.parseUnits("400"));
  });

  it("rejects transfering out with duplicated nonce", async function () {
    for (const user of [user1, user2, user3]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
    }

    await token.connect(user4).approve(stakingAddr, ethers.parseUnits("500"));
    await staking.connect(user4).stake(3600, ethers.parseUnits("500"), []);

    // Sign EIP712 message for Transfer
    const messages = [];
    const signatures = [];

    const transfer = {
      from: user4.address,
      to: user1.address,
      nftIds: [],
      amount: ethers.parseUnits("100"),
      nonces: [0, 1, 2],
    };

    for (const user of [user1, user2, user3]) {
      const message = {
        signer: user.address,
        ...transfer,
      };

      const signed = await signEip712(
        user,
        eip712domain,
        { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
        message
      );

      messages.push(message);
      signatures.push(signed);
    }

    // Transfer the tokens
    await staking.connect(owner).transfer(messages, signatures);

    // Sign EIP712 message for Transfer
    const duplicateMessages = [];
    const duplicateSignatures = [];

    const duplicateTransfer = {
      from: stakingAddr,
      to: user1.address,
      nftIds: [],
      amount: ethers.parseUnits("100"),
      nonces: [1],
    };

    for (const user of [user1, user2, user3]) {
      const message = {
        signer: user.address,
        ...duplicateTransfer,
      };

      const signed = await signEip712(
        user,
        eip712domain,
        { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
        message
      );

      duplicateMessages.push(message);
      duplicateSignatures.push(signed);
    }

    // Transfer the tokens
    expect(
      staking.connect(owner).transfer(duplicateMessages, duplicateSignatures)
    ).to.be.revertedWithCustomError(staking, "NonceUsed(uint256,uint256)");
  });

  it("allows setting a signer for a stake holder", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), []);

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

  it("rejects setting a signer with invalid signature", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), []);

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

    //invalid signature
    const secondSignature = await signEip712(
      user3,
      eip712domain,
      { EIP712SetSigner: EIP712_TYPES.EIP712SetSigner },
      message
    );

    // Set the signer
    await expect(
      staking.connect(owner).setSigner(message, firstSignature, secondSignature)
    ).to.be.revertedWithCustomError(staking, "Forbidden()");
  });

  it("allows getting user stake with bls address", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.parseUnits("500"), []);

    const user1Stake = await staking["getStake(bytes20)"](user1bls);
    expect(user1Stake.amount).to.equal(ethers.parseUnits("500"));
  });

  it("reverts if the NFT is not the expected one", async function () {
    await expect(
      staking.onERC721Received(user1.address, user2.address, 123, "0x")
    ).to.be.revertedWithCustomError(staking, "WrongNFT()");
  });

  it("reverts if accepting NFT is forbidden", async function () {
    await expect(
      nft.connect(user1).safeTransferFrom(user1.address, stakingAddr, 1)
    ).to.be.revertedWithCustomError(staking, "Forbidden()");
  });

  it("allows setting nft price", async function () {
    for (const user of [user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("50"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("50"), []);
    }

    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("255"));
    await staking
      .connect(user1)
      .stake(25 * 60 * 60 * 24, ethers.parseUnits("255"), []);

    // Sign EIP712 message for setNftPrice
    const nftprices = [];
    const signatures = [];

    const nftSetPrice = {
      requester: user1.address,
      nftId: 7,
      price: ethers.parseUnits("5"),
      nonce: 0,
    };

    for (const user of [user1]) {
      const nftprice = {
        signer: user.address,
        ...nftSetPrice,
      };

      const signed = await signEip712(
        user,
        eip712domain,
        { EIP712SetNftPrice: EIP712_TYPES.EIP712SetNftPrice },
        nftprice
      );

      nftprices.push(nftprice);
      signatures.push(signed);
    }

    await staking.connect(user1).setNftPrices(nftprices, signatures);

    const nftSetPriceKey = {
      nftId: 7,
      price: ethers.parseUnits("5"),
      nonce: 0,
    };

    const nftPriceInfoFirst = await staking.getSetNftPriceData(nftSetPriceKey);

    expect(nftPriceInfoFirst.accepted).to.equal(true);

    await staking.connect(user1).setNftPrices(nftprices, signatures);

    // Call the getRequestedSetNftPrice function to check if the address has requested the set of NFT prices
    const hasRequested = await staking.getRequestedSetNftPrice(
      nftSetPriceKey,
      user1.address
    );
    const nftPriceInfoSecond = await staking.getSetNftPriceData(nftSetPriceKey);
    const nftPriceResult = await staking.getPrice(7);

    expect(nftPriceInfoSecond.price).to.equal(ethers.parseUnits("5"));
    expect(nftPriceInfoSecond.accepted).to.equal(true);
    expect(nftPriceInfoSecond.voted).to.equal(ethers.parseUnits("255"));

    expect(nftPriceResult).to.equal(ethers.parseUnits("5"));
    expect(hasRequested).to.equal(true);
  });

  it("rejects set nft price with low voting power", async function () {
    for (const user of [user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("50"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("50"), []);
    }
    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("50"));
    await staking
      .connect(user1)
      .stake(25 * 60 * 60 * 24, ethers.parseUnits("50"), []);

    // Sign EIP712 message for setNftPrice
    const nftprices = [];
    const signatures = [];

    const nftSetPrice = {
      requester: user1.address,
      nftId: 7,
      price: ethers.parseUnits("5"),
      nonce: 0,
    };

    const nftprice = {
      signer: user1.address,
      ...nftSetPrice,
    };

    const signed = await signEip712(
      user1,
      eip712domain,
      { EIP712SetNftPrice: EIP712_TYPES.EIP712SetNftPrice },
      nftprice
    );

    nftprices.push(nftprice);
    signatures.push(signed);

    await staking.connect(user1).setNftPrices(nftprices, signatures);
    const nftSetPriceKey = {
      nftId: 7,
      price: ethers.parseUnits("5"),
      nonce: 0,
    };

    // Call the getRequestedSetNftPrice function to check if the address has requested the set of NFT prices
    const hasRequested = await staking.getRequestedSetNftPrice(
      nftSetPriceKey,
      user1.address
    );
    const nftPriceInfo = await staking.getSetNftPriceData(nftSetPriceKey);
    const nftPriceResult = await staking.getPrice(7);

    expect(nftPriceInfo.price).to.equal(ethers.parseUnits("5"));
    expect(nftPriceInfo.accepted).to.equal(false);
    expect(nftPriceInfo.voted).to.equal(ethers.parseUnits("50"));

    expect(nftPriceResult).to.equal(ethers.parseUnits("0"));
    expect(hasRequested).to.equal(true);
  });

  it("reverts if signatures and setNftPrices length mismatch", async function () {
    for (const user of [user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("50"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("50"), []);
    }
    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("200"));
    await staking
      .connect(user1)
      .stake(25 * 60 * 60 * 24, ethers.parseUnits("200"), []);

    // Sign EIP712 message for setNftPrice
    const nftprices = [];
    const signatures = [];

    const nftSetPrice = {
      requester: user1.address,
      nftId: 7,
      price: ethers.parseUnits("5"),
      nonce: 0,
    };
    const nftSetPrice2 = {
      requester: user1.address,
      nftId: 6,
      price: ethers.parseUnits("5"),
      nonce: 0,
    };

    const nftprice2 = {
      signer: user1.address,
      ...nftSetPrice2,
    };

    const nftprice = {
      signer: user1.address,
      ...nftSetPrice,
    };

    const signed = await signEip712(
      user1,
      eip712domain,
      { EIP712SetNftPrice: EIP712_TYPES.EIP712SetNftPrice },
      nftprice
    );

    nftprices.push(nftprice);
    nftprices.push(nftprice2);
    signatures.push(signed);

    await expect(
      staking.connect(user1).setNftPrices(nftprices, signatures)
    ).to.be.revertedWithCustomError(staking, "LengthMismatch()");
  });

  it("reverts setNftPrices if consensus lock is not reached", async function () {
    await deploy(99999);

    for (const user of [user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("50"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("50"), []);
    }
    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("200"));
    await staking
      .connect(user1)
      .stake(25 * 60 * 60 * 24, ethers.parseUnits("200"), [1, 2]);

    // Sign EIP712 message for setNftPrice
    const nftprices = [];
    const signatures = [];

    const nftSetPrice = {
      requester: user1.address,
      nftId: 7,
      price: ethers.parseUnits("5"),
      nonce: 0,
    };

    const nftprice = {
      signer: user1.address,
      ...nftSetPrice,
    };

    const signed = await signEip712(
      user1,
      eip712domain,
      { EIP712SetNftPrice: EIP712_TYPES.EIP712SetNftPrice },
      nftprice
    );

    nftprices.push(nftprice);
    signatures.push(signed);

    await expect(
      staking.connect(user1).setNftPrices(nftprices, signatures)
    ).to.be.revertedWithCustomError(staking, "Forbidden()");
  });

  it("reverts setNftPrices signer has zero voting power", async function () {
    for (const user of [user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("50"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("50"), []);
    }
    await staking
      .connect(user1)
      .stake(25 * 60 * 60 * 24, ethers.parseUnits("0"), [1, 2]);

    // Sign EIP712 message for setNftPrice
    const nftprices = [];
    const signatures = [];

    const nftSetPrice = {
      requester: user1.address,
      nftId: 7,
      price: ethers.parseUnits("5"),
      nonce: 0,
    };

    const nftprice = {
      signer: user1.address,
      ...nftSetPrice,
    };

    const signed = await signEip712(
      user1,
      eip712domain,
      { EIP712SetNftPrice: EIP712_TYPES.EIP712SetNftPrice },
      nftprice
    );

    nftprices.push(nftprice);
    signatures.push(signed);

    await expect(
      staking.connect(user1).setNftPrices(nftprices, signatures)
    ).to.be.revertedWithCustomError(staking, "VotingPowerZero(uint)");
  });

  it("reverts setNftPrices if signature is invalid", async function () {
    for (const user of [user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("50"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("50"), []);
    }
    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("200"));
    await staking
      .connect(user1)
      .stake(25 * 60 * 60 * 24, ethers.parseUnits("200"), [1, 2]);

    // Sign EIP712 message for setNftPrice
    const nftprices = [];
    const signatures = [];

    const nftSetPrice = {
      requester: user1.address,
      nftId: 7,
      price: ethers.parseUnits("5"),
      nonce: 0,
    };

    const nftprice = {
      signer: user5.address,
      ...nftSetPrice,
    };

    const signed = await signEip712(
      user2,
      eip712domain,
      { EIP712SetNftPrice: EIP712_TYPES.EIP712SetNftPrice },
      nftprice
    );

    nftprices.push(nftprice);
    signatures.push(signed);

    await expect(
      staking.connect(user1).setNftPrices(nftprices, signatures)
    ).to.be.revertedWithCustomError(staking, "InvalidSignature(uint)");
  });

  it("reverts setNftPrices if stake expires before vote", async function () {
    for (const user of [user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("50"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("50"), []);
    }
    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("200"));
    await staking
      .connect(user1)
      .stake(25 * 60 * 60 * 24, ethers.parseUnits("200"), [1, 2]);

    // Sign EIP712 message for setNftPrice
    const nftprices = [];
    const signatures = [];

    const nftSetPrice = {
      requester: user1.address,
      nftId: 7,
      price: ethers.parseUnits("5"),
      nonce: 0,
    };

    await time.increase(60 * 60 * 24 * 364.5);

    const nftprice = {
      signer: user1.address,
      ...nftSetPrice,
    };

    const signed = await signEip712(
      user1,
      eip712domain,
      { EIP712SetNftPrice: EIP712_TYPES.EIP712SetNftPrice },
      nftprice
    );

    nftprices.push(nftprice);
    signatures.push(signed);

    await expect(
      staking.connect(user1).setNftPrices(nftprices, signatures)
    ).to.be.revertedWithCustomError(staking, "StakeExpiresBeforeVote(uint)");
  });

  it("reverts setNftPrices if topic expired", async function () {
    for (const user of [user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("50"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("50"), []);
    }
    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("200"));
    await staking
      .connect(user1)
      .stake(25 * 60 * 60 * 24, ethers.parseUnits("200"), [1, 2]);

    // Sign EIP712 message for setNftPrice
    const nftprices = [];
    const signatures = [];

    const nftSetPrice = {
      requester: user1.address,
      nftId: 7,
      price: ethers.parseUnits("5"),
      nonce: 0,
    };

    const nftprice = {
      signer: user1.address,
      ...nftSetPrice,
    };

    const signed = await signEip712(
      user1,
      eip712domain,
      { EIP712SetNftPrice: EIP712_TYPES.EIP712SetNftPrice },
      nftprice
    );

    nftprices.push(nftprice);
    signatures.push(signed);

    await staking.connect(user1).setNftPrices(nftprices, signatures);
    //go forward in time for 2 days
    await time.increase(2 * 24 * 60 * 60);

    await expect(
      staking.connect(user1).setNftPrices(nftprices, signatures)
    ).to.be.revertedWithCustomError(staking, "TopicExpired(uint)");
  });

  it("reports the correct voting power of user", async function () {
    await token.connect(user1).approve(stakingAddr, ethers.parseUnits("200"));
    await staking
      .connect(user1)
      .stake(25 * 60 * 60 * 24, ethers.parseUnits("200"), [1, 2, 3]);

    const votingPowerOfUser =
      await staking["getVotingPower(bytes20)"](user1bls);

    expect(votingPowerOfUser).to.equal(ethers.parseUnits("200"));
  });

  // Simulations of possible Unchained scenarios
  // 1. Slash a staker for misbheaviour

  it("allows slashing a staker for misbehaviour", async function () {
    // We have 4 different validators on the network
    for (const user of [user1, user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
    }
    // Sign EIP712 message for Transfer (Slash)
    const messages = [];
    const signatures = [];
    const transfer = {
      from: user4.address, // The staker to be slashed
      to: owner.address, // The collector
      nftIds: [],
      amount: ethers.parseUnits("100"), // The amount to be slashed (Based on the severity of the misbehaviour)
      nonces: [0],
    };
    // All validators now attest to the misbehaviour
    for (const user of [user1, user2, user3]) {
      const message = {
        signer: user.address,
        ...transfer,
      };
      const signed = await signEip712(
        user,
        eip712domain,
        { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
        message
      );
      messages.push(message);
      signatures.push(signed);
    }
    // Anyone can call the transfer function to slash the staker
    await staking.connect(owner).transfer(messages, signatures);
    const stake = await staking["getStake(address)"](user4.address);
    // The stake should be reduced by the amount slashed
    expect(stake.amount).to.equal(ethers.parseUnits("400"));
  });

  // 2. Send gas fees from a consumer to a validator
  // From the tokens transferred to the contract by the consumer,
  // the contract can send the gas fees to the validators
  it("allows sending gas fees to validators", async function () {
    // We have 4 different validators on the network
    for (const user of [user1, user2, user3, user4]) {
      await token.connect(user).approve(stakingAddr, ethers.parseUnits("500"));
      await staking
        .connect(user)
        .stake(25 * 60 * 60 * 24, ethers.parseUnits("500"), []);
    }
    // We have one consumer on the network with tokens transferred to Unchained
    // These tokens are locked in the contract and managed by the Unchained
    // consensus protocol (validator votes)
    const user5bls = randomBytes(20);
    await staking.connect(user5).setBlsAddress(user5bls);
    // Fund the consumer account
    await token.transfer(user5.address, ethers.parseUnits("500"));
    // Transfer the tokens to Unchained
    await token.connect(user5).approve(stakingAddr, ethers.parseUnits("500"));
    await staking.connect(user5).transferToUnchained(ethers.parseUnits("500"));
    // Sign EIP712 message for Transfer (Gas Fees)
    const messages = [];
    const signatures = [];
    const transfer = {
      from: stakingAddr, // Fee/Consumer tokens are locked in the contract
      to: user4.address, // The validator to receive the gas fees
      nftIds: [],
      amount: ethers.parseUnits("100"), // The amount to be sent as gas fees
      nonces: [0],
    };
    // All validators now attest to the gas fees
    for (const user of [user1, user2, user3]) {
      const message = {
        signer: user.address,
        ...transfer,
      };
      const signed = await signEip712(
        user,
        eip712domain,
        { EIP712Transfer: EIP712_TYPES.EIP712Transfer },
        message
      );
      messages.push(message);
      signatures.push(signed);
    }
    // Keep a record of the validator balance before the transfer
    const preTransfer = await token.balanceOf(user4.address);
    // Anyone can call the transfer function to send the gas fees
    await staking.connect(owner).transfer(messages, signatures);
    // The validator should receive the gas fees
    const postTransfer = await token.balanceOf(user4.address);
    expect(postTransfer).to.equal(preTransfer + ethers.parseUnits("100"));
  });

  it("rejects non-owner calls", async function () {
    await expect(
      staking.connect(user1).recoverERC20(tokenAddr, owner.address, 100)
    ).to.be.revertedWithCustomError(
      staking,
      "OwnableUnauthorizedAccount(address)"
    );
  });

  it("should prevent reentrancy attacks", async function () {
    const Attacker = await ethers.getContractFactory("Attacker");
    const attacker = await Attacker.deploy(stakingAddr, tokenAddr);

    const attackerAddr = await attacker.getAddress();
    await staking.transferOwnership(attackerAddr);
    const attackerbls = randomBytes(20);
    await attacker.setBls(attackerbls);

    await token.connect(owner).approve(attackerAddr, ethers.parseUnits("500"));
    await token.connect(owner).transfer(attackerAddr, ethers.parseUnits("500"));
    await attacker.approve(stakingAddr, ethers.parseUnits("500"));

    // Set BLS addresses for users
    await attacker.stakeToStakingContract(
      25 * 60 * 60 * 24,
      ethers.parseUnits("500"),
      []
    );
    await time.increase(30 * 24 * 60 * 60);
    // Call the recoverERC20 function from the attacker contract
    await expect(attacker.attack()).to.emit(attacker, "AttackFailed");

    // Check balances after the attack
    const stakingBalance = await token.balanceOf(stakingAddr);
    const attackBalance = await token.balanceOf(attackerAddr);

    expect(attackBalance).to.equal(ethers.parseUnits("500"));

    // Assert that the Staking contract's balance remains the same
    expect(stakingBalance).to.equal(0);
  });
});
