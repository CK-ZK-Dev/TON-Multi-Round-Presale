import { toNano, address } from '@ton/core';
import { PresaleV2UserDetails } from '../wrappers/PresaleV2UserDetails';
import { PresaleV2Contract } from '../wrappers/PresaleV2Contract';
import { NetworkProvider } from '@ton/blueprint';
require('dotenv').config();

// Updates the presales contract's claim start time.
export async function run(provider: NetworkProvider) {
    if (process.env.PRESALES_CONTRACT && process.env.USER_ADDRESS) {
        const userAddress = address(process.env.USER_ADDRESS);
        const presalesContractAddress = address(process.env.PRESALES_CONTRACT);
        const presaleContract = provider.open(PresaleV2Contract.fromAddress(presalesContractAddress));

        const presalesUserContractAddress = await presaleContract.getPresaleUserDetailsAddress(userAddress);
        const presaleUserDetails = provider.open(PresaleV2UserDetails.fromAddress(presalesUserContractAddress));

        const presalesDetails = await presaleUserDetails.getUserPresaleData();
        console.log('presale user contract address ', presalesUserContractAddress);
        console.log('presale details of user ', presalesDetails);
    }
}
