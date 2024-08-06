# Node Terminal smart contracts

This is blockchain part of Node Terminal project. It contains smart contracts used in application.

## Overview

### Usage

#### Before start

Create `.env` file from the `.env.example` file

#### Install Node and Yarn

[Node](http://nodejs.org/) at least v20 and [Yarn](https://classic.yarnpkg.com/lang/en/docs/install/). You should be able to run the following command after the installation procedure below. Example:

```bash
$ node --version
20.x

$ yarn --version
1.22.x
```

#### Install packages

```bash
yarn install
```

#### Compile

```bash
yarn compile
```

#### QA

To run code static analysis run command

```bash
yarn static-analyze
```

To run tests execute command

```bash
yarn test
```

You can report gas usage for each tested methods in smart contracts

```bash
REPORT_GAS=true yarn test
```

To show tests coverage report execute

```bash
yarn coverage
```

#### Smart contracts deployment

Use [Hardnat Ignition](https://hardhat.org/ignition/docs/getting-started#overview) plugin to deploy new contracts.

1. Prepare deployment module
2. Add file defining deployment parameters. Name should contain chain id of destination network, e.g. `parameters-137.json` for Polygon chain
3. Execute deployment

    ```bash
    yarn hardhat ignition deploy MODULE_FILE_PATH --network NETWORK --parameters PARAMETERS_FILE_PATH
    ```

4. Verify deployed contracts providing `deploymentId`

    ```bash
    yarn hardhat ignition verify DEPLOYMENT_ID
    ```

    For example:

    ```bash
    yarn hardhat ignition verify chain-137
    ```
