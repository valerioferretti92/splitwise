# Splitwise
This project is meant to be an experiment with the **Ethereum blockchain** ecosystem. The aim is to implement the backend of an
application for splitting expenses among a group of people. The application will only record who is owed what without providing 
in-built payment functionalities.  
The backend logic is implemented through smart contracts meant to be deployed and run on en Ethereum blockchain infrastructure.
The application would be resiliant to censorchip and extremely available as it would rely on an entire network of blockchain
nodes for backend execution. After UI development, a possible improvement would be the implementation of payment solutions with
both traditional currency and cryptocurrencies.

The project is still in progress. For its implementation the following tools have been used:
- **Ganache**, to mimick the blockchain infrastrucure
- **The Truffle Suite** for compiling and deploying contracts on the Ganache blockchian node
- **Solidity** v0.5.0 for SmartContract implementation

## How to install dependencies

- Ganache: https://github.com/trufflesuite/ganache
- Truffle Suite: `sudo npm install --unsafe-perm -g truffle`

## How to deploy

- Launch Ganache application
- Inside Ganache application: Settings > Add Project && Browse to get truffle-config.js > Save and restart
- `cd splitwise && truffle compile && truffle migrate`
