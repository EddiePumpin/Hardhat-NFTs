const { run } = require("hardhat")

async function verify(contractAddress, args) {
    console.log("Verifying contract......")
    try {
        run("verify:verify", {
            address: contractAddress,
            ethUsdPriceFeedAddress: args,
        })
    } catch (e) {
        if (e.message.toLowerCase().includes("Already Verified")) {
            console.log("Already Verified!")
        } else {
            console.log(e)
        }
    }
}

module.exports = { verify }
