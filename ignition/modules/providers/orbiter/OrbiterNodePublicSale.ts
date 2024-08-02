import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';
import orbiterNodesModule from './OrbiterNodes';

const orbiterNodeSaleModule = buildModule('OrbiterNodeSale', (m) => {
  const { orbiterNodes } = m.useModule(orbiterNodesModule);

  // const owner = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'; // localhost
  const owner = '0xc65F1bcBFc6eD856dbD335bc9f4e748b029bc0Ff'; // sepolia
  const nodesNFT = orbiterNodes;
  const feesReceiver = '0xE904ae44F94647b276568d112270AFa7ad75D30E';
  const maxBatchMintNum = 10;
  const erc20Token = '0xBeAd86Ab655A3C883D7c0d03a00B3A9E92eeb09c'; // sepolia
  const availablePaymentTokens = [erc20Token];
  const signers = [owner];
  const governors = [owner];
  const nodesNumbers = [30, 50, 70, 100, 120];
  const prices = [600e6, 663e6, 733, 810, 895];

  const orbiterNodePublicSale = m.contract('OrbiterNodeSale', [
    owner,
    nodesNFT,
    feesReceiver,
    maxBatchMintNum,
    availablePaymentTokens,
    signers,
    governors,
    nodesNumbers,
    prices
  ]);

  m.call(orbiterNodes, 'setNodeSellContract', [orbiterNodePublicSale]);

  // const orbiterNodesContract = m.contractAt('OrbiterNodes', orbiterNodes);

  return { orbiterNodes };
});

export default orbiterNodeSaleModule;
