import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const orbiterNodesModule = buildModule('OrbiterNodes', (m) => {
  const owner = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
  // const owner = '0xc65F1bcBFc6eD856dbD335bc9f4e748b029bc0Ff';
  const name = 'ON Test';
  const symbol = 'ONT';
  const inputbaseURI = '';
  const governors = [owner];
  const maxSupply = 200_000;

  const orbiterNodes = m.contract('OrbiterNodes', [name, symbol, inputbaseURI, owner, governors, maxSupply]);

  return { orbiterNodes };
});

export default orbiterNodesModule;
