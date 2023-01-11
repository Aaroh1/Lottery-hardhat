const { frontEndContractsFile, frontEndAbiFile } = require("../helper-hardhat-config")
//file location to save abi and contratc address
const fs = require("fs")
const { network } = require("hardhat")

module.exports = async () => {
    if (process.env.UPDATE_FRONT_END) {
        console.log("Writing to front end...")
        await updateContractAddresses()
        await updateAbi()
        console.log("Front end written!")
    }
}

async function updateAbi() {
    const Lottery = await ethers.getContract("Lottery")
    fs.writeFileSync(frontEndAbiFile, Lottery.interface.format(ethers.utils.FormatTypes.json))
}

async function updateContractAddresses() {
    const Lottery = await ethers.getContract("Lottery")
    const contractAddresses = JSON.parse(fs.readFileSync(frontEndContractsFile, "utf8"))
    if (network.config.chainId.toString() in contractAddresses) {
        if (!contractAddresses[network.config.chainId.toString()].includes(Lottery.address)) {
            contractAddresses[network.config.chainId.toString()].push(Lottery.address)
        }
    } else {
        contractAddresses[network.config.chainId.toString()] = [Lottery.address]
    }
    fs.writeFileSync(frontEndContractsFile, JSON.stringify(contractAddresses))
}
module.exports.tags = ["all", "frontend"]