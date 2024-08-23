import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';
import { ethers } from 'hardhat';

const proxyModule2 = buildModule('ProxyModule2', (m) => {
  const proxyAdminOwner = m.getAccount(0);
  const decimals = m.getParameter('decimals');

  const erc20TestToken = m.contract('ERC20TestToken2');

  const initializeInterface = new ethers.Interface(['function initialize(uint256 decimals_)']);
  const initializeEncoded = initializeInterface.encodeFunctionData('initialize', [decimals]);
  const proxy = m.contract('TransparentUpgradeableProxy', [erc20TestToken, proxyAdminOwner, initializeEncoded]);

  const proxyAdminAddress = m.readEventArgument(proxy, 'AdminChanged', 'newAdmin');

  const proxyAdmin = m.contractAt('ProxyAdmin', proxyAdminAddress);

  return { proxyAdmin, proxy };
});

const erc20TestTokenModule = buildModule('ERC20TestToken2', (m) => {
  const { proxy, proxyAdmin } = m.useModule(proxyModule2);

  const erc20TestToken = m.contractAt('ERC20TestToken2', proxy);

  return { erc20TestToken, proxy, proxyAdmin };
});

export default erc20TestTokenModule;
