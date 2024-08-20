struct RoundDetails {
    startTime: Int;
    entireDuration: Int;
    totalSoldInCurrentRound: Int;
    maxTokensToSell: Int;
    tokenPrice: Int;
}

message(0x64693997) InitializeTokenWalletsAndSetRounds {
    usdtTokenWallet: Address;
    saleTokenWallet: Address;
    rounds: map<Int, RoundDetails>;
    totalRounds: Int;
}

message(0xeb476445) InitializeTokenWallets {
    usdtTokenWallet: Address;
    saleTokenWallet: Address;
}

message(0x7362d09c) TokenNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forward_payload: Slice as remaining;
}

message(0xf8a7ea5) TokenTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}


message(0xef97f2d7) ChangeSaleClaimTime {
    saleClaimTime: Int;
}

message(0xbc0e2dec) SaleTime {
    saleStartTime: Int;
}

message(0xaf692001) SaleClaimTime {
    saleStartTime: Int;
    saleClaimTime: Int;
}

message(0xa9a44b5f) UserClaimed {
    user: Address;
    usdtAmount: Int;
    tonAmount: Int;
    saleTokenAmount: Int;
}
message(0x03c672ba) WithdrawTokens {
    query_id: Int as uint64;
    tokenWallet: Address;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x06d5d907) UpdateMaxTokensToBuy {
    newMaxTokensInSinglePurchase: Int;
}

message(0xa6a5f637) TokensWithdrawn {
    token_wallet: Address;
    amount: Int;
    destination: Address;
    owner: Address;
}

message(0x95450156) UpdatePaymetDetails {
    paymentWallet1: Address;
    paymentWallet2: Address;
    splitPercent: Int;
}

message(0x633b35ad) PaymentDetailsUpdated {
    paymentWallet1: Address;
    paymentWallet2: Address;
    splitPercent: Int;
    owner: Address;
    timestamp: Int;
}

message(0xa52cb077) UpdateTONPriceInUSD {
    newTONPrice: Int;
}

message(0x50ae6ae4) TONPriceUpdated {
    oldTONPrice: Int;
    newTONPrice: Int;
    updatedTime: Int;
}

message(0x318de7db) PurchaseDetails {
    user: Address;
    purchasedAmount: Int;
}

message(0x4ed717d2) UpdateGasConsumption {
    gasConsumption: Int;
}

message(0xb08c06f3) SetCurrentRound{
    newRound: Int;
}

message(0xd6ea2b12) TonPayment{
    forward_payload: Slice as remaining;

}

message(0xf99e89fb) SetDynamicTimeFlag {
    set: Bool;
}

message(0x06ef7922) UpdateBlacklistedStatusOfUser {
    user: Address;
    isBlacklisted: Bool;
}

message(0xd0d09133) UpdateSaleTokenBalance {
    newSaleTokenBalance: Int;
}

message(0xefd55ed9) ChangeAdmin {
    newAdmin: Address;
}

message(0xd4e5f39b) UpdateRound {
    round: RoundDetails;
    roundId: Int;
}

message(0x9db3317c) AddExtraRounds{
    extraRounds: Int;
    rounds: map<Int, RoundDetails>;
}