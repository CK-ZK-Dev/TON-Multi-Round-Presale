message(0x1a5ffc51) ClaimToken {
    query_id: Int as uint64;
    from: Address;
    forward_ton_amount: Int as coins;
    custom_payload: Cell;
    forward_payload: Slice as remaining;
}
message(0x0823975e) ClaimTokenInternal {
    query_id: Int as uint64;
    usdtAmount: Int as coins;
    tonAmount: Int as coins;
    saleTokenAmount: Int as coins;
    from: Address;
    forward_ton_amount: Int as coins;
    custom_payload: Cell;
    forward_payload: Slice as remaining;
}
message(0x3be4511c) PurchaseToken {
    query_id: Int;
    usdtAmount: Int?;
    tonAmount: Int?;
    saleTokenPurchasedAmount: Int;
}

message(0xf45b40f9) PurchaseUsingUSDT {
    user: Address;
    usdtAmount: Int;
    saleTokenPurchasedAmount: Int;
    timestamp: Int;
}
message(0xbd24d379) PurchaseUsingTON {
    user: Address;
    tonAmount: Int;
    saleTokenPurchasedAmount: Int;
    timestamp: Int;
}
message(0xf9cd28e2) UpdateBlacklistStatus {
    isBlacklisted: Bool;
}

inline fun refundGasWithRemainingValue(to: Address) {
    send(SendParameters{
            to: to,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: "refundGas".asComment(),
            bounce: false
        }
    );
}

inline fun transferTONByPayingGasSeparately(to: Address, value: Int, comment: String) {
    send(SendParameters{
            to: to,
            value: value,
            mode: SendPayGasSeparately | SendIgnoreErrors,
            body: comment.asComment(),
            bounce: false
        }
    );
}