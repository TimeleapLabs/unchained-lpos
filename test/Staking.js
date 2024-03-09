describe("UnchainedStaking", function () {
  let staking, token, nft;
  let owner, user1;

  // FIXME
  beforeEach(async function () {
    [owner, user1] = await ethers.getSigners();

    // Deploy Mock ERC20 token
    const Token = await ethers.getContractFactory("MockERC20");
    token = await Token.deploy("MockToken", "MTK");
    await token.deployed();

    // Deploy Mock ERC721 NFT
    const NFT = await ethers.getContractFactory("MockERC721");
    nft = await NFT.deploy("MockNFT", "MNFT");
    await nft.deployed();

    // Deploy the Staking contract
    const Staking = await ethers.getContractFactory("UnchainedStaking");
    staking = await Staking.deploy(
      token.address,
      nft.address,
      10,
      owner.address,
      "UnchainedStaking",
      "1"
    );
    await staking.deployed();

    // Mint tokens and NFT to user1
    await token.mint(user1.address, ethers.utils.parseEther("1000"));
    await nft.mint(user1.address, 1);

    // Approve Staking contract to spend tokens and NFT
    await token
      .connect(user1)
      .approve(staking.address, ethers.utils.parseEther("1000"));
    await nft.connect(user1).setApprovalForAll(staking.address, true);
  });

  it("allows users to stake tokens and NFTs", async function () {
    await expect(
      staking
        .connect(user1)
        .stake(60 * 60 * 24, ethers.utils.parseEther("500"), [1], true)
    )
      .to.emit(staking, "Staked")
      .withArgs(
        user1.address,
        ethers.constants.AnyNumber,
        ethers.utils.parseEther("500"),
        [1],
        true
      );

    // Check balances and ownership
    expect(await token.balanceOf(staking.address)).to.equal(
      ethers.utils.parseEther("500")
    );
    expect(await nft.ownerOf(1)).to.equal(staking.address);
  });

  it("allows users to unstake after lock period", async function () {
    await staking
      .connect(user1)
      .stake(1, ethers.utils.parseEther("500"), [1], true);

    // Increase time to surpass the stake duration
    await ethers.provider.send("evm_increaseTime", [2]);
    await ethers.provider.send("evm_mine");

    await expect(staking.connect(user1).unstake())
      .to.emit(staking, "UnStaked")
      .withArgs(user1.address, ethers.constants.AnyNumber, [1]);

    // Check balances and ownership
    expect(await token.balanceOf(user1.address)).to.equal(
      ethers.utils.parseEther("500")
    );
    expect(await nft.ownerOf(1)).to.equal(user1.address);
  });

  it("rejects staking with zero amount", async function () {
    await expect(
      staking.connect(user1).stake(60 * 60 * 24, 0, [1], true)
    ).to.be.revertedWith("AmountZero()");
  });

  it("rejects staking with zero duration", async function () {
    await expect(
      staking.connect(user1).stake(0, ethers.utils.parseEther("500"), [1], true)
    ).to.be.revertedWith("DurationZero()");
  });

  it("rejects staking when already staked without unstaking", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.utils.parseEther("100"), [1], true);
    await expect(
      staking
        .connect(user1)
        .stake(60 * 60 * 24, ethers.utils.parseEther("100"), [2], true)
    ).to.be.revertedWith("AlreadyStaked()");
  });

  it("rejects unstaking before duration expires", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.utils.parseEther("500"), [1], true);

    // Attempt to unstake immediately
    await expect(staking.connect(user1).unstake()).to.be.revertedWith(
      "NotUnlocked()"
    );
  });

  it("successfully slashes a staker based on consensus", async function () {
    // This is highly dependent on your slashing mechanism.
    // The following is a very simplified version assuming a direct slash call can be made.

    // Setup a scenario where `user1` can be slashed
    // Note: The actual setup would depend on your contract's logic for slashing
    await staking
      .connect(user1)
      .stake(60 * 60 * 24 * 365, ethers.utils.parseEther("500"), [1], true);

    // Assume `owner` has the authority to slash directly for this test
    await expect(
      staking
        .connect(owner)
        .slash(
          [user1.address],
          [ethers.utils.parseEther("100")],
          ["incidentID"]
        )
    )
      .to.emit(staking, "Slashed")
      .withArgs(
        user1.address,
        owner.address,
        ethers.utils.parseEther("100"),
        ethers.constants.AnyNumber,
        "incidentID"
      );

    // Verify the slash was successful
    const postSlashStake = await staking.stakeOf(user1.address);
    expect(postSlashStake.amount).to.equal(ethers.utils.parseEther("400"));
  });

  it("allows increasing the stake", async function () {
    await staking
      .connect(user1)
      .stake(60 * 60 * 24, ethers.utils.parseEther("500"), [1], true);

    // Increase stake
    await staking
      .connect(user1)
      .increaseStake(ethers.utils.parseEther("500"), [2]);
    const postIncreaseStake = await staking.stakeOf(user1.address);

    expect(postIncreaseStake.amount).to.equal(ethers.utils.parseEther("1000"));
    expect(postIncreaseStake.nftIds.length).to.equal(2);
  });
});
