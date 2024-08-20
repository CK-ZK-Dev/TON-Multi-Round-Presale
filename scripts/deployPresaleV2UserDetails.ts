import { toNano } from '@ton/core';
import { PresaleV2UserDetails } from '../wrappers/PresaleV2UserDetails';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const presaleV2UserDetails = provider.open(await PresaleV2UserDetails.fromInit());

    await presaleV2UserDetails.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(presaleV2UserDetails.address);

    // run methods on `presaleV2UserDetails`
}
