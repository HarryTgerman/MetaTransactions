
import { BytesLike } from "@ethersproject/bytes";

interface DeterministicDeploymentInfo {
    factory: string
    WETH: string
    factroy_code_hash: BytesLike
}

interface Config {
    [network:string]: DeterministicDeploymentInfo
}



const config:Config = {
    "31337": {
        factory: "0x5757371414417b8c6caad45baef941abc7d3ab32",
        WETH: "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270",
        factroy_code_hash: "0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
      }
}

export default config;
