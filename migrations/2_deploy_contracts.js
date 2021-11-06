const RogueLand = artifacts.require("RogueLand");
const Register = artifacts.require("Register");

module.exports = async function(deployer) {
  //await deployer.deploy(Register);
  //const registerContract = await Register.deployed();
  await deployer.deploy(RogueLand, '0x76f099cd22E737FC38f17FA07aA95dACe8e53e4e');
  //const RogueLandContract = await Register.deployed();
};
