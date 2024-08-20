import { toNano, address, Contract } from '@ton/core';
import { PresaleV2Contract } from '../wrappers/PresaleV2Contract';
import { NetworkProvider } from '@ton/blueprint';
require('dotenv').config();

export async function run(provider: NetworkProvider) {
    if (process.env.PRESALES_CONTRACT) {
        const deployedContract = address(process.env.PRESALES_CONTRACT);
        const splitterContract = provider.open(await PresaleV2Contract.fromAddress(deployedContract));

        await splitterContract.send(
            provider.sender(),
            {
                value: toNano('0.5'),
            },
            'CloseFunds',
        );
    }
}
