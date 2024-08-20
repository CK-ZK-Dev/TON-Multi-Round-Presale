import { toNano, address, beginCell } from '@ton/core';
import { PresaleV2Contract } from '../wrappers/PresaleV2Contract';
import { NetworkProvider } from '@ton/blueprint';
require('dotenv').config();

// Updates the presales contract's claim start time.
export async function run(provider: NetworkProvider) {
    if (process.env.PRESALES_CONTRACT) {
        const presalesContractAddress = address(process.env.PRESALES_CONTRACT);
        const presaleContract = provider.open(PresaleV2Contract.fromAddress(presalesContractAddress));

        const presalesDetails = await presaleContract.getIsSaleTime();
        const tonReq = await presaleContract.getTonWrtSaleToken(120000000000n, 1n);
        const usdtReq = await presaleContract.getUsdtWrtSaleToken(10000000000n, 1n);
        console.log('tonReq  ', tonReq);
        console.log('usdtReq ', usdtReq);
    }
}
