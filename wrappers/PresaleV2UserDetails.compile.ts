import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/presale_v2_user_details.tact',
    options: {
        debug: true,
    },
};
