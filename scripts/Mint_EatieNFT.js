const hre = require("hardhat");

const CONTRACT_ADDRESS = "0xebbcb87549B240FA2e44F31da8eB2a156E2435D1";
const META_DATA_URL = "https://dak6rila99vz.cloudfront.net/metadata/";

function timeout(delay) {
  return new Promise((res) => setTimeout(res, delay));
}

async function mintEatieNFT(contractAddress, metaDataURL) {
  while (1) {
    try {
      const EatieNFT = await hre.ethers.getContractFactory("EatieNFT");
      // const [owner] = await ethers.getSigners();
      const eventMint = await EatieNFT.attach(contractAddress).mintNFT(
        "0xF17d9B89F13dabAcfDe4740304ef3e46b7e73a32",
        metaDataURL
      );
      await eventMint.wait();
      break;
    } catch (e) {}
  }
  // console.log("NFT minted to:", owner.address);
}

let numberOfNFTs = 1000;
async function mintMany() {
  for (let i = 1; i <= numberOfNFTs; i++) {
    await mintEatieNFT(CONTRACT_ADDRESS, `${META_DATA_URL}${i}.json`);
    // await timeout(5000);
    console.log(`${i} NFT minted success`, i);
  }
}
mintMany();
// mintNFT(CONTRACT_ADDRESS, META_DATA_URL)
//   .then(() => process.exit(0))
//   .catch((error) => {
//     console.error(error);
//     process.exit(1);
//   });
