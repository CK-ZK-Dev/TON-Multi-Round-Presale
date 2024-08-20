import { toNano, address } from '@ton/core';
import { PresaleV2Contract } from '../wrappers/PresaleV2Contract';
import { NetworkProvider } from '@ton/blueprint';
require('dotenv').config();

// Updates the presales contract's claim start time.
export async function run(provider: NetworkProvider) {
    if (process.env.PRESALES_CONTRACT) {
        const presalesContractAddress = address(process.env.PRESALES_CONTRACT);
        const presaleContract = provider.open(PresaleV2Contract.fromAddress(presalesContractAddress));

        await presaleContract.send(
            provider.sender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'UpdateTONPriceInUSD',
                newTONPrice: 6260000000n,
            },
        );
    }
}
