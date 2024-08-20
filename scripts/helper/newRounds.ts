// rounds.ts
import { Dictionary, DictionaryValue } from '@ton/core';
import { RoundDetails } from '../../wrappers/PresaleV2Contract';

// Function to serialize and parse RoundDetails
const roundDetailsValue: DictionaryValue<RoundDetails> = {
    serialize(src: RoundDetails, builder: any): void {
        builder.writeBigInt(src.startTime);
        builder.writeBigInt(src.entireDuration);
        builder.writeBigInt(src.totalSoldInCurrentRound);
        builder.writeBigInt(src.maxTokensToSell);
        builder.writeBigInt(src.tokenPrice);
    },
    parse(src: any): RoundDetails {
        return {
            $$type: 'RoundDetails',
            startTime: src.readBigInt(),
            entireDuration: src.readBigInt(),
            totalSoldInCurrentRound: src.readBigInt(),
            maxTokensToSell: src.readBigInt(),
            tokenPrice: src.readBigInt(),
        };
    },
};

// Create the dictionary key
const roundsKey = Dictionary.Keys.BigInt(257);

// Create empty dictionary
const rounds = Dictionary.empty<bigint, RoundDetails>(roundsKey, roundDetailsValue);

// Add entries to the dictionary
// rounds.set(4n, {
//     $$type: 'RoundDetails',
//     startTime: 0n,
//     entireDuration: 5400n,
//     totalSoldInCurrentRound: 0n,
//     maxTokensToSell: 300000000n * 1000000000n,
//     tokenPrice: 32n, //0.000000029
// });

// rounds.set(5n, {
//     $$type: 'RoundDetails',
//     startTime: 0n,
//     entireDuration: 5400n,
//     totalSoldInCurrentRound: 0n,
//     maxTokensToSell: 300000000n * 1000000000n,
//     tokenPrice: 33n, //0.00000003
// });

rounds.set(6n, {
    $$type: 'RoundDetails',
    startTime: 0n,
    entireDuration: 5500n,
    totalSoldInCurrentRound: 0n,
    maxTokensToSell: 300000000n * 1000000000n,
    tokenPrice: 34n, //0.00000003
});


export function getRounds(): Dictionary<bigint, RoundDetails> {
    return rounds;
}
