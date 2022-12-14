const INITIAL_PRICE = "25000000000000000000";
const BASE_FEE = "250000000000000000";
const GAS_PRICE_LINK = 1e9;
const { network, ethers } = require("hardhat")

const FUND_AMOUNT = ethers.utils.parseEther("1") // 1 Ether, or 1e18 (10^18) Wei

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    if (chainId == 31337) {
        await deploy("VRFCoordinatorV2Mock", {
            from: deployer,
            log: true,
            args: [BASE_FEE, GAS_PRICE_LINK],
          });
    }}
module.exports.tags = ["all", "mocks"];