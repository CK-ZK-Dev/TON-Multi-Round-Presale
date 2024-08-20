import { toNano, address } from '@ton/core';
import { PresaleV2Contract } from '../wrappers/PresaleV2Contract';
import { JettonContract } from '../wrappers/JettonContract';
import { NetworkProvider } from '@ton/blueprint';
// import { getRounds } from './helper/roundData';
import { getRounds } from './helper/newRounds';
require('dotenv').config();

// Allows the user to claim token from the contract.
export async function run(provider: NetworkProvider) {
    if (process.env.TETHER_JETTON && process.env.SALE_JETTON && process.env.PRESALES_CONTRACT) {
        const presalesContractAddress = address(process.env.PRESALES_CONTRACT);
        const presaleContract = provider.open(PresaleV2Contract.fromAddress(presalesContractAddress));

        await presaleContract.send(
            provider.sender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'AddExtraRounds',
                rounds: getRounds(),
                extraRounds: 1n,
            },
        );
    }
}