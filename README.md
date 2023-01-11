# Decentralized Lottery Project

- This project contains the implementation of an automated (time bound) decentralised Lottery.
- The project allows players to enter and contest for the Lottery by paying a base price (0.1 eth).
- Once enough time passes (checked by Chainlink automation keepers), a winner from among the entrants is picked randomly (using the Chainlink VRF) and rewarded the entire prize pool.


## Tech-Stack
- solidity
- hardhat
- ethers js
- chainlink VRF
- chainlink automation

Try running some of the following tasks:

```shell
yarn hardhat compile
yarn hardhat test
yarn hardhat node
yarn hardhat deploy
```
