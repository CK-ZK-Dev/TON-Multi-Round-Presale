import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { PresaleV2UserDetails } from '../wrappers/PresaleV2UserDetails';
import '@ton/test-utils';

describe('PresaleV2UserDetails', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let presaleV2UserDetails: SandboxContract<PresaleV2UserDetails>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        presaleV2UserDetails = blockchain.openContract(await PresaleV2UserDetails.fromInit());

        deployer = await blockchain.treasury('deployer');

        const deployResult = await presaleV2UserDetails.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: presaleV2UserDetails.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and presaleV2UserDetails are ready to use
    });
});
