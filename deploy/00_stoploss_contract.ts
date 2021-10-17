import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';
import {parseEther} from 'ethers/lib/utils';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;

  const {deployer, simpleERC20Beneficiary} = await getNamedAccounts();

  await deploy('SimpleERC20', {
    from: deployer,
    args: [simpleERC20Beneficiary, parseEther('1000000000')],
    log: true,
  });

  
};

// const encodedData = this._handlerAddress
//  this._abiEncoder.encode(
//     ["address", "uint256", "address"],
//     [outputToken, minReturn, this._handlerAddress]


// const encodedEthOrder = await this._gelatoLimitOrders.encodeEthOrder(
//     this._moduleAddress,
//     ETH_ADDRESS, // we also use ETH_ADDRESS if it's MATIC
//     owner,
//     witness,
//     encodedData,
//     secret
//   );
//   data = this._gelatoLimitOrders.interface.encodeFunctionData(
//     "depositEth",
//     [encodedEthOrder]
//   );
//   value = amount;
//   to = this._gelatoLimitOrders.address;

//   data = this._erc20OrderRouter.interface.encodeFunctionData(
//     "depositToken",
//     [
//       amount,
//       this._moduleAddress,
//       inputToken,
//       owner,
//       witness,
//       encodedData,
//       secret,
//     ]
//   );
//   value = constants.Zero;
//   to = this._erc20OrderRouter.address;
  


export default func;
func.tags = ['SimpleERC20'];

