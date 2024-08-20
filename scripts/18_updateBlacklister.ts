import { toNano, address } from '@ton/core';
import { NetworkProvider } from '@ton/blueprint';
import { PresaleV2Contract } from '../wrappers/PresaleV2Contract';
require('dotenv').config();

export async function run(provider: NetworkProvider) {
    if (process.env.PRESALES_CONTRACT && process.env.USER_ADDRESS) {
        const presalesAddress = address(process.env.PRESALES_CONTRACT);
        const userAddress = address(process.env.USER_ADDRESS);
        const presaleContract = provider.open(PresaleV2Contract.fromAddress(presalesAddress));
        await presaleContract.send(
            provider.sender(),
            {
                value: toNano('0.1'),
            },
            {
                $$type: 'UpdateBlacklister',
                user: userAddress,
                isBlacklisted: false,
            },
        );
    }

    // run methods on `counterContract`
}
