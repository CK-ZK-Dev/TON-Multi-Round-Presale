import { toNano, address } from '@ton/core';
import { PresaleV2Contract } from '../wrappers/PresaleV2Contract';
import { JettonContract } from '../wrappers/JettonContract';
import { NetworkProvider } from '@ton/blueprint';
import { RoundDetails } from '../wrappers/PresaleV2Contract';
require('dotenv').config();

// Allows the user to claim token from the contract.
export async function run(provider: NetworkProvider) {
    if (process.env.TETHER_JETTON && process.env.SALE_JETTON && process.env.PRESALES_CONTRACT) {
        const presalesContractAddress = address(process.env.PRESALES_CONTRACT);
        const presaleContract = provider.open(PresaleV2Contract.fromAddress(presalesContractAddress));

        const roundData: RoundDetails = {
            $$type: 'RoundDetails',
            startTime: 1723812416n,
            entireDuration: 120n,
            totalSoldInCurrentRound: 200000000000000n,
            maxTokensToSell: 3000000000n * 1000000000n,
            tokenPrice: 2n, //0.00000003
        };

        await presaleContract.send(
            provider.sender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'UpdateRound',
                round: roundData,
                roundId: 1n,
            },
        );
    }
}
