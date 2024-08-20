import { toNano, address } from '@ton/core';
import { PresaleV2Contract } from '../wrappers/PresaleV2Contract';
import { JettonContract } from '../wrappers/JettonContract';
import { NetworkProvider } from '@ton/blueprint';
// import { getRounds } from './helper/roundData';
import { getRounds } from './helper/roundDataPresales';
require('dotenv').config();

// Allows the user to claim token from the contract.
export async function run(provider: NetworkProvider) {
    if (process.env.TETHER_JETTON && process.env.SALE_JETTON && process.env.PRESALES_CONTRACT) {
        const presalesContractAddress = address(process.env.PRESALES_CONTRACT);
        const presaleContract = provider.open(PresaleV2Contract.fromAddress(presalesContractAddress));
        const usdtToken = address(process.env.TETHER_JETTON);
        const saleToken = address(process.env.SALE_JETTON);
        const usdtContract = provider.open(await JettonContract.fromAddress(usdtToken));
        const saleContract = provider.open(await JettonContract.fromAddress(saleToken));

        const usdtTokenWallet = await usdtContract.getGetWalletAddress(presalesContractAddress);
        const saleTokenWallet = await saleContract.getGetWalletAddress(presalesContractAddress);

        console.log('presale usdt wallet ', usdtTokenWallet);
        console.log('presale sale token wallet ', saleTokenWallet);

        await presaleContract.send(
            provider.sender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'InitializeTokenWalletsAndSetRounds',
                usdtTokenWallet: usdtTokenWallet,
                saleTokenWallet: saleTokenWallet,
                rounds: getRounds(),
                totalRounds: 3n,
            },
        );
    }
}
