import { toNano, address } from '@ton/core';
import { PresaleV2Contract } from '../wrappers/PresaleV2Contract';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    if (
        process.env.USER_ADDRESS &&
        process.env.TETHER_JETTON &&
        process.env.SALE_JETTON &&
        process.env.PAYMENT_WALLET1 &&
        process.env.PAYMENT_WALLET2
    ) {
        const owner = address(process.env.USER_ADDRESS);
        const usdtToken = address(process.env.TETHER_JETTON);
        const saleToken = address(process.env.SALE_JETTON);
        const maxTokensInSinglePurchase = 1500000000n * 1000000000n; // 200 Token  (10^9 format)
        const saleStartTime = 1719295996n;
        const admin = address(process.env.USER_ADDRESS);
        const paymentWallet1 = address(process.env.PAYMENT_WALLET1);
        const paymentWallet2 = address(process.env.PAYMENT_WALLET2);
        const splitPercentage = 50000n;      //50%
        const tonPriceInUSD = 6330000000n;

        const presaleV2Contract = provider.open(
            await PresaleV2Contract.fromInit(
                owner,
                usdtToken,
                saleToken,
                maxTokensInSinglePurchase,
                saleStartTime,
                admin,
                paymentWallet1,
                paymentWallet2,
                splitPercentage,
                tonPriceInUSD,
            ),
        );

        await presaleV2Contract.send(
            provider.sender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            },
        );

        await provider.waitForDeploy(presaleV2Contract.address);
    }
    

    // run methods on `presaleV2Contract`
}
