import { toNano, address, beginCell } from '@ton/core';
import { PresaleV2Contract } from '../wrappers/PresaleV2Contract';
import { NetworkProvider } from '@ton/blueprint';
require('dotenv').config();

// Updates the presales contract's claim start time.
export async function run(provider: NetworkProvider) {
    if (process.env.PRESALES_CONTRACT) {
        const presalesContractAddress = address(process.env.PRESALES_CONTRACT);
        const presaleContract = provider.open(PresaleV2Contract.fromAddress(presalesContractAddress));

        const forward_payload = beginCell().storeInt(10000000000, 256).endCell().asSlice();

        const presalesDetails = await presaleContract.getAmountFromSlice(forward_payload);
        console.log('round details ', presalesDetails);
    }
}
