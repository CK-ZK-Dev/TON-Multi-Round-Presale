import { toNano, address, Contract,beginCell } from '@ton/core';
import { PresaleV2Contract } from '../wrappers/PresaleV2Contract';
import { NetworkProvider } from '@ton/blueprint';
require('dotenv').config();

export async function run(provider: NetworkProvider) {
    if (process.env.PRESALES_CONTRACT) {
        const deployedContract = address(process.env.PRESALES_CONTRACT);
        const presaleContract = provider.open(await PresaleV2Contract.fromAddress(deployedContract));
        const forward_payload = beginCell().storeInt(1500000000000000000n, 256).endCell().asSlice(); //// 15000000
        // const forward_payload = beginCell().storeInt(1500000000000000000n, 256).endCell().asSlice(); ////1_500_000_000
        // const forward_payload = beginCell().storeInt(120000000000, 256).endCell();

        await presaleContract.send(
            provider.sender(),
            {
                value: toNano('0.887900473'),
            },
            {
                $$type: 'TonPayment',
                forward_payload: forward_payload,
            },
        );
    }
}
