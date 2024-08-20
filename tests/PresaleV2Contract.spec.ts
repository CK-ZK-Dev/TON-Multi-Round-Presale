import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { PresaleV2Contract } from '../wrappers/PresaleV2Contract';
import '@ton/test-utils';

describe('PresaleV2Contract', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let presaleV2Contract: SandboxContract<PresaleV2Contract>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        presaleV2Contract = blockchain.openContract(await PresaleV2Contract.fromInit());

        deployer = await blockchain.treasury('deployer');

        const deployResult = await presaleV2Contract.send(
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
            to: presaleV2Contract.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and presaleV2Contract are ready to use
    });
});
