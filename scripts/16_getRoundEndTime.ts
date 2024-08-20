import { toNano, address, beginCell } from '@ton/core';
import { PresaleV2Contract } from '../wrappers/PresaleV2Contract';
import { NetworkProvider } from '@ton/blueprint';
require('dotenv').config();

// Updates the presales contract's claim start time.
export async function run(provider: NetworkProvider) {
    if (process.env.PRESALES_CONTRACT) {
        const presalesContractAddress = address(process.env.PRESALES_CONTRACT);
        const presaleContract = provider.open(PresaleV2Contract.fromAddress(presalesContractAddress));

        const roundEndTime = await presaleContract.getRoundEndTime(1n);
        console.log('end time ', roundEndTime);
    }
}
