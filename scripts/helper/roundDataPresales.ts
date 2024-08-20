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
rounds.set(1n, {
    $$type: 'RoundDetails',
    startTime: 0n,
    entireDuration: 5400n,
    totalSoldInCurrentRound: 0n,
    maxTokensToSell: 3000000000n * 1000000000n,
    tokenPrice: 2n, //0.000000029
});

rounds.set(2n, {
    $$type: 'RoundDetails',
    startTime: 0n,
    entireDuration: 5400n,
    totalSoldInCurrentRound: 0n,
    maxTokensToSell: 3000000000n * 1000000000n,
    tokenPrice: 3n, //0.00000003
});

rounds.set(3n, {
    $$type: 'RoundDetails',
    startTime: 0n,
    entireDuration: 5400n,
    totalSoldInCurrentRound: 0n,
    maxTokensToSell: 1500000000n * 1000000000n,
    tokenPrice: 4n, //0.000000031
});

export function getRounds(): Dictionary<bigint, RoundDetails> {
    return rounds;
}
