const { expect } = require("chai");
const { ethers } = require("hardhat");
const { randomBytes } = require("crypto");

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
    { name: "nftTracker", type: "address" },
    { name: "threshold", type: "uint256" },
    { name: "expiration", type: "uint256" },
    { name: "nonce", type: "uint256" },
  ],
  EIP712SetParamsKey: [
    { name: "token", type: "address" },
    { name: "nft", type: "address" },
    { name: "nftTracker", type: "address" },
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
  let staking, token, nft, nftTracker;
  let owner, user1, user2, user3, user4, user5;
  let stakingAddr, tokenAddr, nftAddr, nftTrackerAddr;
  let user1bls, user2bls, user3bls, user4bls;
  let eip712domain;

  beforeEach(async function () {
    [owner, user1, user2, user3, user4, user5] = await ethers.getSigners();

    // Deploy Mock ERC20 token
    const Token = await ethers.getContractFactory("DKenshi");
    token = await Token.deploy();

    // Deploy Mock ERC721 NFT
    const NFT = await ethers.getContractFactory("DKatana");
    nft = await NFT.deploy();

    // Mint NFTs
    await nft.mint(0, 100);

    //Deploy Mock NFT tracker
    const NFTTracker = await ethers.getContractFactory("NFTTracker");
    nftTracker = await NFTTracker.deploy();

    tokenAddr = await token.getAddress();
    nftAddr = await nft.getAddress();
    nftTrackerAddr = await nftTracker.getAddress();

    // Deploy the Staking contract
    const Staking = await ethers.getContractFactory("UnchainedStaking");
    staking = await Staking.deploy(
      tokenAddr,
      nftAddr,
      nftTrackerAddr,
      10,
      "Unchained",
      "1"
    );

    stakingAddr = await staking.getAddress();
    await nftTracker.transferOwnership(nftAddr);

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

  it("rejects recovering the stake token", async function () {
    await staking.connect(user1).stake(1, ethers.parseUnits("500"), [1]);
    await expect(
      staking.connect(owner).recoverERC20(tokenAddr, owner.address, 100)
    ).to.be.revertedWithCustomError(staking, "Forbidden()");
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
      nftTracker: nftTrackerAddr,
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
      nftTracker: nftTrackerAddr,
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
      nftTracker: nftTrackerAddr,
      threshold: 60,
      expiration: 60 * 60 * 24 * 7,
      collector: owner.address,
      nonce: 0,
    };

    for (const user of [user1, user1]) {
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
    expect(
      staking.connect(owner).setParams(messages, signatures)
    ).to.be.revertedWithCustomError(staking, "AlreadyVoted(uint256)");
  });

  it("allows transfering in and out of the Unchained Network", async function () {
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
    const preTransfer = await token.balanceOf(user1.address);
    await staking.connect(owner).transfer(messages, signatures);

    // Transfer data should be available
    const slashData = await staking.getTransferData(transfer);
    expect(slashData.to).to.equal(user1.address);
    expect(slashData.amount).to.equal(ethers.parseUnits("100"));
    expect(slashData.voted).to.equal(ethers.parseUnits("1500"));
    expect(slashData.accepted).to.equal(true);

    // getRequestedTransferOut reports correct values
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
});
