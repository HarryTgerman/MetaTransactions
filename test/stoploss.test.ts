import chai, { expect } from "chai";
import { deployments, ethers, getChainId, network} from "hardhat";
import { solidity } from "ethereum-waffle";
import { 
  RelayerPineCore__factory, 
  RelayerPineCore, 
  Stoploss__factory, 
  Stoploss, 
  UniswapV2Handler, 
  UniswapV2Handler__factory, 
  UniswapV2Router01, 
  UniswapV2Router01__factory, } from '../typechain'
import { BytesLike, Signer, utils, Wallet } from "ethers";
import { joinSignature } from '@ethersproject/bytes'

chai.use(solidity);


 

describe("PineCore", async function () {
  let 
  pineCore: RelayerPineCore, 
  stoplossModule: Stoploss, 
  ethAddress:string, 
  usdc: string, 
  handler:UniswapV2Handler, 
  relayer: Signer, 
  AMM:UniswapV2Router01;

  const randomSecret = utils.hexlify(utils.randomBytes(19)).replace("0x", "");
  // 0x67656c61746f6e6574776f726b = gelatonetwork in hex
  const fullSecret = `0x67656c61746f6e6574776f726b${randomSecret}`;

  const { privateKey: secret, address: witness }:{privateKey: BytesLike, address:string}  = new Wallet(fullSecret);
  const amount1 = 140 * 1e6, amount2 = 100 * 1e6, amount3 = 180 * 1e6, amount4 = 160 * 1e6;
  usdc = "0x2791bca1f2de4661ed88a30c99a7a9449aa84174"
  const encodedOrderData = ethers.utils.defaultAbiCoder.encode(['address', 'uint256', 'uint256'], [usdc, amount1, amount2])                     
  const encodedOrderSuccessData = ethers.utils.defaultAbiCoder.encode(['address', 'uint256', 'uint256'], [usdc, amount3, amount4])                     



  async function sign(address: string, priv: string): Promise<string> {
    const hash = ethers.utils.solidityKeccak256(['address'], [address])

    const wallet = new Wallet(priv)

    // Unsafe but not for this.
    return joinSignature(wallet._signingKey().signDigest(hash))
  }

  beforeEach(async() => {
    const [deployer, trader] = await ethers.getSigners();
    // get contracts and addresses 
    await deployments.fixture(['all'])
    const pineCoreFactory = new RelayerPineCore__factory(deployer);
    pineCore = await pineCoreFactory.attach("0x38c4092b28dAB7F3d98eE6524549571c283cdfA5");

    const stoplossModuleFactory = new Stoploss__factory(deployer);
    stoplossModule = await stoplossModuleFactory.deploy();

    const handlerFactory = new UniswapV2Handler__factory(deployer);
    handler = await handlerFactory.attach((await deployments.get('UniswapV2Handler')).address);

    ethAddress = await pineCore.ETH_ADDRESS()

    const amm= new UniswapV2Router01__factory(deployer);
    AMM = await amm.attach("0x5757371414417b8c6caad45baef941abc7d3ab32")


    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [await pineCore.GELATO()],
    });
    relayer = await ethers.getSigner(await pineCore.GELATO())


    }) 

  describe("Create ETH Order", async function () {

    beforeEach(async() => {
      const [deployer, trader] = await ethers.getSigners();

      const encodedOrder = await pineCore.encodeEthOrder(
        stoplossModule.address,         // Stoploss orders module
        ethAddress,                     // ETH Address
        trader.address,                 // Owner of the order: ;
        witness,                        // Witness public address
        encodedOrderData,
        secret                          // Witness secret
      )
      await pineCore.connect(trader).depositEth(
        encodedOrder,
        {
          value:  ethers.utils.parseEther("100"), // deposit 100 Matic (native Token of Polygon)
        }
      ) 

      const encodedOrderSuccess = await pineCore.encodeEthOrder(
        stoplossModule.address,         // Stoploss orders module
        ethAddress,                     // ETH Address
        trader.address,                 // Owner of the order: ;
        witness,                        // Witness public address
        encodedOrderSuccessData,
        secret                          // Witness secret
      )
      await pineCore.connect(trader).depositEth(
        encodedOrderSuccess,
        {
          value:  ethers.utils.parseEther("100"), // deposit 100 Matic (native Token of Polygon)
        }
      ) 
    }) 

   it("Order should exist", async()=> {
    const [deployer, trader] = await ethers.getSigners();
     const orderExist = await pineCore.existOrder(
      stoplossModule.address,         // Stoploss orders module
      ethAddress,                     // ETH Address
      trader.address,                 // Owner of the order: ;
      witness,                        // Witness public address
      encodedOrderData
      )
     expect(orderExist).to.eq(true);
   })

   it("Order can not be executed", async()=> {
    const [deployer, trader] = await ethers.getSigners();
    const canExecute = await pineCore.canExecuteOrder(
      stoplossModule.address, 
      ethAddress, 
      trader.address, 
      witness, 
      encodedOrderData,
      utils.defaultAbiCoder.encode(['address', 'address', 'uint256'], [handler.address, await relayer.getAddress(), utils.parseEther("0")]),
    ) 
    expect(canExecute).to.eq(false);
   })

   it("Success order can be executed", async()=> {
    const [deployer, trader] = await ethers.getSigners();
    const canExecute = await pineCore.canExecuteOrder(
      stoplossModule.address, 
      ethAddress, 
      trader.address, 
      witness, 
      encodedOrderSuccessData,
      utils.defaultAbiCoder.encode(['address', 'address', 'uint256'], [handler.address, await relayer.getAddress(), utils.parseEther("0")]),
    ) 
    expect(canExecute).to.eq(true);
   })

   it("Success order executed successfully", async()=> {
    const [deployer, trader] = await ethers.getSigners();
    
    // execute order as relayer 
     const tx =  await pineCore.connect(relayer).executeOrder(
      stoplossModule.address,
      ethAddress,
      trader.address,
      encodedOrderSuccessData,
      await sign(await relayer.getAddress(),secret) ,
      utils.defaultAbiCoder.encode(['address', 'address', 'uint256'], [handler.address, await relayer.getAddress(), utils.parseEther("0")]),
      )
      await tx.wait()
      let ABI = [
        "function balanceOf(address account) external view returns (uint256)"
    ];
    // get traders usdc balance
    const usdcContract = new ethers.Contract(usdc, ABI, trader.provider);
    const balance = await usdcContract.balanceOf(trader.address)
    // order should execute under stoploss conditions
    expect(parseInt(balance)).to.below(amount3).and.above(amount4);
   })
   
  });
});
