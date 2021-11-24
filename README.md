[![RELEASE - AWS build & deploy](https://github.com/IX-Swap/nft-metaverse/actions/workflows/release.yaml/badge.svg?branch=master)](https://github.com/IX-Swap/nft-metaverse/actions/workflows/release.yaml) 

# Infrastructure for IX Swap NFTs.

The repository contains assets and infrastructure IaaC setup to support IX Swap issued NFTs as well as some of the underlying core NFT functionality within the IX Swap NFT ecosystem.

# IXS-NFT

# Install all dependencies
`npm install`

# Build all contracts
`npm run build`

# Run Tests
`npm test`

# Deploy to Rinkeby Testnet
`npm run deployStage`

# Deploy to Polygon Mainnet
`npm run deployProd`


# Blockchain Deployments

## Rinkeby


```
ADDRESS: 0xd8e06BF1410b8F9E5086DF10d6Ab0cDfF48126A6
```

Core Contracts:

```
[CFG] DEFAULTADMIN 0xd8e06BF1410b8F9E5086DF10d6Ab0cDfF48126A6
[CFG] MINTER 0xd8e06BF1410b8F9E5086DF10d6Ab0cDfF48126A6
[CFG] PAUSER 0xd8e06BF1410b8F9E5086DF10d6Ab0cDfF48126A6

IXS-NFT = 0x6ECc7A1dCe9DD04A18a03bf0a537E9F77cd194fA
IXS-NFT > totalSupply = 188
IXS-NFT > #MINTER > balance = 188
IXS-NFT > #admin = 0xd8e06BF1410b8F9E5086DF10d6Ab0cDfF48126A6
IXS-NFT > #pauser = 0xd8e06BF1410b8F9E5086DF10d6Ab0cDfF48126A6
IXS-NFT > #minter = 0xd8e06BF1410b8F9E5086DF10d6Ab0cDfF48126A6

