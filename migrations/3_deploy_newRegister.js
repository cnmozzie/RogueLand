const NewRegister = artifacts.require("NewRegister");

module.exports = async function(deployer) {
  await deployer.deploy(NewRegister);
};
