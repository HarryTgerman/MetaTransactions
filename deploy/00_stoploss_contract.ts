import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';
import {parseEther} from 'ethers/lib/utils';
import config from '../config';
import { getChainId } from 'hardhat';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;

  const {deployer} = await getNamedAccounts();

  const deploymentProps = config[await getChainId()]
  
  const Stoploss = await deploy('Stoploss', {
    from: deployer,
    log: true,
  });
  const UniswapV2Handler = await deploy('UniswapV2Handler', {
    from: deployer,
    args: [deploymentProps.factory, deploymentProps.WETH, deploymentProps.factroy_code_hash],
    log: true,
  });

 
  
};




export default func;
func.tags = ['all'];

