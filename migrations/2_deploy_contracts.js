const RogueLand = artifacts.require("RogueLand");
const Register = artifacts.require("Register");

module.exports = async function(deployer) {
  await deployer.deploy(Register);
  const registerContract = await Register.deployed();
  await deployer.deploy(RogueLand, registerContract.address);
  const RogueLandContract = await Register.deployed();
};
