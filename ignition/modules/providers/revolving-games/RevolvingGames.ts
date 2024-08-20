import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';
import hre from 'hardhat';
import erc20TestTokenModule from '../../test/ERC20TestToken';

const revolvingGamesModule = buildModule('RevolvingGames', (m) => {
  let paymentToken;
  if (hre.network.name in ['hardhat', 'localhost']) {
    console.log(`localhost`);
    const { erc20TestToken } = m.useModule(erc20TestTokenModule);
    paymentToken = erc20TestToken;
  } else {
    paymentToken = m.getParameter('paymentToken');
  }

  const owner = m.getParameter('owner');
  const nodeProviderWallet = m.getParameter('nodeProviderWallet');
  const commissionsWallet = m.getParameter('commissionsWallet');
  const ntCommissionsInBp = m.getParameter('ntCommissionsInBp');
  const tier1MaxSupply = m.getParameter('tier1MaxAllowedNodes');
  const tier2MaxSupply = m.getParameter('tier2MaxAllowedNodes');
  const tier1NodePrice = m.getParameter('tier1NodePrice');
  const tier2NodePrice = m.getParameter('tier2NodePrice');

  const revolvingGamesTier1 = m.contract(
    'NodesSale',
    [owner, paymentToken, nodeProviderWallet, commissionsWallet, tier1MaxSupply, ntCommissionsInBp, tier1NodePrice],
    { id: 'Tier1' }
  );

  const revolvingGamesTier2 = m.contract(
    'NodesSale',
    [owner, paymentToken, nodeProviderWallet, commissionsWallet, tier2MaxSupply, ntCommissionsInBp, tier2NodePrice],
    { id: 'Tier2' }
  );

  return { revolvingGamesTier1, revolvingGamesTier2 };
});

export default revolvingGamesModule;
