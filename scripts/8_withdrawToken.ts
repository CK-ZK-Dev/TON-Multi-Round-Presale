import { toNano, address, beginCell, Cell, Dictionary } from '@ton/core';
import { sha256_sync } from '@ton/crypto';
import { PresaleV2Contract } from '../wrappers/PresaleV2Contract';
import { NetworkProvider } from '@ton/blueprint';
import { setCustomPayload, payloadData } from './helper/jettonDetails';
require('dotenv').config();

// Transfer the sales tokens to the contract before claim time starts.
export async function run(provider: NetworkProvider) {
    if (process.env.USER_ADDRESS && process.env.TETHER_JETTON_PRESALE_WALLET && process.env.PRESALES_CONTRACT) {
        const JettonWalletAddress = address(process.env.TETHER_JETTON_PRESALE_WALLET); //of user
        const presalesAddress = address(process.env.PRESALES_CONTRACT);
        const jettonWalletContract = provider.open(PresaleV2Contract.fromAddress(presalesAddress));

        const tokenReceiverAddress = address(process.env.USER_ADDRESS);

        const query_id = 1n;
        const amount = 1n; // 5 (in 10^6)
        const destination = tokenReceiverAddress;
        const response_destination = tokenReceiverAddress;

        const custom_payload = setCustomPayload();
        const forward_ton_amount = 0n;

        const forward_payload = payloadData();

        await jettonWalletContract.send(
            provider.sender(),
            {
                value: toNano('0.15'),
            },
            {
                $$type: 'WithdrawTokens',
                query_id: query_id,
                tokenWallet: JettonWalletAddress,
                amount: amount,
                destination: destination,
                response_destination: response_destination,
                custom_payload: custom_payload,
                forward_ton_amount: forward_ton_amount,
                forward_payload: forward_payload,
            },
        );
    }

    // run methods on `counterContract`
}

function toSha256(s: string): bigint {
    return BigInt('0x' + sha256_sync(s).toString('hex'));
}

function toTextCell(s: string): Cell {
    return beginCell().storeUint(0, 8).storeStringTail(s).endCell();
}

