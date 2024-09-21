const pinataSDK = require("@pinata/sdk")
const path = require("path")
require("dotenv").config()

// In order to work with PINATA you need to work with the API key and secret fpr pinata to know that it id from us

const pinataApiKey = process.env.PINATA_API_KEY
const pinataApiSecret = process.env.PINATA_API_SECRET
const pinta = pinataSDK(pinataApiKey, pinataApiSecret)

// ./images/randomNft/
async function storeImages(imagesFilePath) {
  const fullImagesPath = path.resolve(imagesFilePath)
  const files = fs.readdirSync(fullImagesPath)
  //console.log(files)
  let responses = []
  console.log("Uploading to IPFS")
  for (fileIndex in files) {
    console.log(`Working on ${fileIndex}....`)
    const readableStreamForFile = fs.createReadStream(
      `${fullImagesPath}/${files[fileIndex]}`
    ) // (`${fullImagesPath}/${files[fileIndex]}`) is an image file
    try {
      const response = await pinataApiKey.pinFileToIPFS(readableStreamForFile) // pinata stuff
      responses.push(response)
    } catch (error) {
      console.log(error)
    }
  }
  return { responses, files }
}

async function storeTokenUriMetadata(meta) {
  try {
    const response = await pinataApiKey.pinJSONToIPFS(metadata)
    return response
  } catch (error) {
    console.log(error)
  }
  return null
}

module.exports = { storeImages, storeTokenUriMetadata }
