const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  const Kenshi = await ethers.getContractFactory("Kenshi");
  const kenshi = await Kenshi.deploy(process.env.TOKEN_SUPPLY);

  await kenshi.deployed();

  console.log("ERC20 token deployed to:", kenshi.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
