const RogueLand = artifacts.require("RogueLand");
const LoserLand = artifacts.require("LoserLand");
const Building = artifacts.require("Building");

module.exports = async function(deployer) {
  const squidAddress = '0xc9a9be0f88b44889f30ea0978e984fb5a6efe68b';
  await deployer.deploy(LoserLand, 'LoserLand', '地');
  const loserLandContract = await LoserLand.deployed();
  await deployer.deploy(Building, loserLandContract.address, squidAddress);
  //await deployer.deploy(Building, '0x4238f095de38e3D13330c56F553aa9ecD77025eb', squidAddress);
  const buildingContract = await Building.deployed();
  const hepAddress = '0xfd83168291312a0800f44610974350c569d12e42';
  await deployer.deploy(RogueLand, buildingContract.address, hepAddress, squidAddress);
  //await deployer.deploy(RogueLand, '0x26d1e186e7A6b96D84A5F0BbB27226F3c80DEfD8', hepAddress, squidAddress);
  //const RogueLandContract = await Register.deployed();
};
