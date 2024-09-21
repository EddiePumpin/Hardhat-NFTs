const { network, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
const {
  storeImages,
  storeTokenUriMetadata,
} = require("../utils/uploadToPinata")

const imagesLocation = "./image/randomNft"

const metadataTemplate = {
  name: "",
  description: "",
  image: "", // This is going to be replaced with image URI of IPFS we just created
  attributes: [
    {
      trait_type: "cuteness",
      value: 100,
    },
  ],
}

let vrfCoordinatorV2Mock, subscriptionId

const FUND_AMOUNT = "10000000000000000000" // 10 LINK     ethers.utils.parseEther("")

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()

  let tokenUris
  // We going to work with mocks because we used chainlink
  if (process.env.UPLOAD_TO_PINATA == "true") {
    tokenUris = await handleTokenUris()
  }

  // We need to get ipfs hashes of our images. We can do that through:
  // 1. With our IPFS node which we can do manually or programmatically. Visit https://docs.ipfs.tech/
  // 2. pinata - https://pinata.cloud/
  // 3. https://nft.storage/. Check repo for the scripts

  if (developmentChains.includes(network.name)) {
    const vrfCoordinatorV2Mock = await ethers.getContractAt(
      "VRFCoordinatorV2Mock"
    )
    vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address
    const transactionResponse = await vrfCoordinatorV2Mock.createSubscription()
    const transactionReceipt = await transactionResponse.wait(1)
    subscriptionId = transactionReceipt.event[0].args.subId
    await vrfCoordinatorV2Mock.fundSubscription(subscriptionId, FUND_AMOUNT)
  } else {
    vrfCoordinatorV2Address = networkConfig[chainId].vrfCoordinatorV2
    subscriptionId = networkConfig[chainId].subscriptionId
  }

  log["------------------------"]
  await storageImages("imagesLocation")
  const args = [
    vrfCoordinatorV2Address,
    subscriptionId,
    networkConfig[chainId].gasLane,
    networkConfig[chainId].callbackGasLimit,
    TokenUris,
    networkConfig[chainId].mintFee,
  ]

  const randomIpfsNft = await deploy("RandomIpfsNft", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  })
  log("-------------------------")

  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    log("Verifying....")
    await verify(randomIpfsNft.address, args)
  }
}

// This function will upload our token to pinata
async function handleTokenUris() {
  tokenUris = []
  // We need to store the image in IPFS and
  // We need to store the metadata in IPFS
  const { responses: imageUploadResponses, files } = await storageImages(
    imagesLocation
  ) // responses wil be the list of imageUploadesponses from pinata
  for (imageUploadResponseIndex in imageUploadResponses) {
    // create metadata
    // upload metadata
    let tokenUriMetadata = { ...metadataTemplate } //... means unpack. This line means tokenUriMetadata is eaqual to metadataTemplate above
    tokenUriMetadata.name = files[imageUploadResponseIndex].replace(".png", "") // files will be one of those files. pug.png, shiba_inu.png, st_benard.png
    tokenUriMetadata.description = `An adorable ${tokenUriMetadata.name} pup!`
    tokenUriMetadata.image =
      `ipfs://${imageUploadResponses[imageUploadResponseIndex].ipfsHash}` | // This is used to give ipfs an image
      console.log(`Uploading ${tokenUriMetadata.name}...`)
    // store the JSON to pinata / Pinata
    const metadataUploadResponse = await storeTokenUriMetadata(tokenUriMetadata)
    tokenUris.push(`ipfs://${metadataUploadResponse.IpfsHash}`)
  }
  console.log("Token URIs Uploaded! They are:")
  console.log(tokenUris)
  return tokenUris
}

module.exports.tags = ["all", "randomipfs", "main"]
