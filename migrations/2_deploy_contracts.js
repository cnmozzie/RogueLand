const RogueLand = artifacts.require("RogueLand");

module.exports = function(deployer) {
  const nftAddress = '0xe031188b0895afd3f3c32b2bf27fbd1ab9e8c9ea';
  deployer.deploy(RogueLand);
};
