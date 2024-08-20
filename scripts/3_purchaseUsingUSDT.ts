import { toNano, address, beginCell, Cell, Dictionary } from '@ton/core';
import { sha256_sync } from '@ton/crypto';
import { NetworkProvider } from '@ton/blueprint';
import { JettonWallet } from '../wrappers/JettonWallet';
require('dotenv').config();

// User can purchase sale token from the presales contract.
export async function run(provider: NetworkProvider) {
    if (process.env.USER_ADDRESS && process.env.USDT_USER_WALLET && process.env.PRESALES_CONTRACT) {
        const userAddress = address(process.env.USER_ADDRESS);
        const JettonWalletAddress = address(process.env.USDT_USER_WALLET); //of user
        const jettonWalletContract = provider.open(JettonWallet.fromAddress(JettonWalletAddress));

        const tokenReceiverAddress = address(process.env.PRESALES_CONTRACT);

        const query_id = 1n;
        // const amount = 1n * 1000000n;// (4 in 10^6)
        // const amount = 29n * 1000000n; // (30 in 10^6)
        // const forward_payload = beginCell().storeInt(1000000000000000000n, 256).endCell(); //1_000_000_000

        // const amount = 59000000n; // (30 in 10^6)
        // const forward_payload = beginCell().storeInt(1100000000000000000n, 256).endCell(); //1_000_000_000

        // const amount = 10800000n;
        // const forward_payload = beginCell().storeInt(360000000000000000n, 256).endCell();

         const amount = 4500100n;
         const forward_payload = beginCell().storeInt(1500000000000000000n, 256).endCell();

        // const amount = 8n * 1000000n; // (8 in 10^6)
        // const amount = 40n * 1000000n; // (8 in 10^6)
        // const amount = 260n * 1000000n; // (260 in 10^6)
        // const amount = 80n * 1000000n; // (8 in 10^6)
        const destination = tokenReceiverAddress;
        const response_destination = userAddress;
        const custom_payload = setCustomPayload();
        const forward_ton_amount = 1000000000n;

        // const forward_payload = beginCell().storeInt(250000000000, 256).endCell(); // 250 token
        // const forward_payload = beginCell().storeInt(10000000000, 256).endCell(); // 40 token
        // const forward_payload = beginCell().storeInt(120000000000, 256).endCell(); // 120 token
        // const forward_payload = beginCell().storeUint(0, 32).storeStringTail('Presale Transfer').endCell();

        await jettonWalletContract.send(
            provider.sender(),
            {
                value: toNano('1.115'),
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
