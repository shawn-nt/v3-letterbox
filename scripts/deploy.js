// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const { ContractType } = require("hardhat/internal/hardhat-network/stack-traces/model");
require('dotenv').config();
const { string } = require("hardhat/internal/core/params/argumentTypes");
const { BigNumber } = require("@ethersproject/bignumber");

async function main() {
  //console.log(process.env);
  process.env;
  const Contract = await hre.ethers.getContractFactory("LetterboxV3");
  const contract = await Contract.deploy("LetterboxV3", "LTRBOXv3");

  await contract.deployed();

  console.log("Contract deployed to: ", contract.address);

  let user1 = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
  let user2 = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
  
  console.log("Minting stamp..");

  const tx = await contract.mintStamp(user1, "https://narrativetrails.xyz/stampuri/0" );
  console.log("--wait method for monitor--");
  const receipt = await tx.wait();
  //console.log(receipt.events);
  for (const event of receipt.events){
    console.log("Event ", event.event, " with args ", event.args.resourceMetadata);
   }
  
  // console.log(receipt.events[4].event);
  // console.log(receipt.events[4].args.toString());

  contract.once("resourceAdded", (res1, res2, res3)=> {
    console.log("res1 = ", res1.toString());
    console.log("res2 = ", res2.toString());
    console.log("res3 = ", JSON.stringify(res3));
  });
  console.log("writing a stamp");
  await contract.mintStamp(user2, "https://narrativetrails.xyz/stampuri/222" );
  console.log("wrote");
  // contract.on("resourceAdded", (res1, res2, res3) => {
  //   console.log("tokenid, resourceid, metadata = ", res1.toString(), " ,", res2.toString(), " ,", res3.toString());
  // });
  console.log("writing more stamps...");
  await contract.mintStamp("0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", "https://narrativetrails.xyz/stampuri/22" );
  console.log("writing a letterbox") ;

  await contract.mintLetterbox(user1, "https://narrativetrails.xyz/letterbox/100");

  console.log("stamping letterbox");

  //await contract.stampToLetterbox(user2, "1", true);
  await contract.letterboxToStamp(user2, "1");

  console.log("done");


  
  // console.log(" -- wait method -- ")
  // const tx = await contract.mintStamp("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", "https://narrativetrails.xyz/stampuri/0" );
  // const receipt = await tx.wait();
  // for (const event of receipt.events){
  //   console.log("Event ", event.event, " with args ", event.args.resourceMetadata);
  //  }
  // }
  // console.log("--- filters method ---");
  // const addedResources = await contract.filters.resourceAdded();
  // console.log("addedResources filter = ", addedResources);

  // console.log("...listener method..." );
  // const watchingIt = await contract.on(contract.resourceAdded, listener);
  // console.log("listener = ", watchingIt);

};
  


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
