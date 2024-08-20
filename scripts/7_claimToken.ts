import { toNano, address } from '@ton/core';
import { PresaleV2Contract } from '../wrappers/PresaleV2Contract';
import { NetworkProvider } from '@ton/blueprint';
import { setCustomPayload, payloadData } from './helper/jettonDetails';
require('dotenv').config();

// Allows the user to claim token from the contract.
export async function run(provider: NetworkProvider) {
    if (process.env.USER_ADDRESS && process.env.PRESALES_CONTRACT) {
        const userAddress = address(process.env.USER_ADDRESS);
        const presalesContractAddress = address(process.env.PRESALES_CONTRACT);
        const presaleContract = provider.open(PresaleV2Contract.fromAddress(presalesContractAddress));

        const custom_payload = setCustomPayload();
        const forward_ton_amount = 0n;

        const forward_payload = payloadData().asSlice();

        await presaleContract.send(
            provider.sender(),
            {
                value: toNano('0.15'),
            },
            {
                $$type: 'ClaimToken',
                query_id: 1n,
                from: userAddress,
                forward_ton_amount: 0n,
                custom_payload: custom_payload,
                forward_payload: forward_payload,
            },
        );
    }
}
