const SplitwiseGroup = artifacts.require("SplitwiseGroup");
const Splitwise = artifacts.require("Splitwise")

module.exports = function(deployer) {
  deployer.deploy(SplitwiseGroup).then((swGroup) => {
    return deployer.deploy(Splitwise, swGroup.address);
  });
};
