import { toNano, address, beginCell, Cell, Dictionary } from '@ton/core';
import { sha256_sync } from '@ton/crypto';
import { NetworkProvider } from '@ton/blueprint';
import { JettonWallet } from '../wrappers/JettonWallet';
require('dotenv').config();

// Transfer the sales tokens to the contract before claim time starts.
export async function run(provider: NetworkProvider) {
    if (process.env.USER_ADDRESS && process.env.SALE_USER_WALLET && process.env.PRESALES_CONTRACT) {
        const userAddress = address(process.env.USER_ADDRESS);
        const JettonWalletAddress = address(process.env.SALE_USER_WALLET); //of user
        const jettonWalletContract = provider.open(JettonWallet.fromAddress(JettonWalletAddress));

        const tokenReceiverAddress = address(process.env.PRESALES_CONTRACT);

        const query_id = 1n;
        const amount = 6060000000n * 1000000000n; // 6060000000 (in 10^9)
        const destination = tokenReceiverAddress;
        const response_destination = userAddress;
        const custom_payload = setCustomPayload();
        const forward_ton_amount = 51112200n;

        const forward_payload = beginCell().storeUint(0, 32).storeStringTail('Presale Transfer').endCell();

        await jettonWalletContract.send(
            provider.sender(),
            {
                value: toNano('0.15'),
            },
            {
                $$type: 'TokenTransfer',
                query_id: query_id,
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

function setCustomPayload(): Cell {
    const itemContentDict = Dictionary.empty(Dictionary.Keys.BigUint(256), Dictionary.Values.Cell())
        .set(toSha256('Comment'), toTextCell('payload comment'))
        .set(toSha256('second'), toTextCell('example data'));
    return beginCell().storeUint(0, 8).storeDict(itemContentDict).endCell();
}
