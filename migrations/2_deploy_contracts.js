const RogueLand = artifacts.require("RogueLand");
const Register = artifacts.require("Register");

module.exports = async function(deployer) {
  //await deployer.deploy(Register);
  //const registerContract = await Register.deployed();
  const cherryNFTAddress = '0xb95f4d790c684eff1a32a63f285311e28f283a19';
  const hepAddress = '0xfD83168291312A0800f44610974350C569d12e42';
  const squidAddress = '0xc9a9be0f88b44889f30ea0978e984fb5a6efe68b';
  await deployer.deploy(RogueLand, cherryNFTAddress, hepAddress, squidAddress);
  //const RogueLandContract = await Register.deployed();
};
