struct SalesDetails {
    maxTokensInSinglePurchase: Int;
    totalSold: Int;
    saleStartTime: Int;
    saleClaimTime: Int;
    saleTokenBalance: Int;
    currentRound: Int;
    totalRounds: Int;
    usdRaised: Int;
}
struct TokenDetails {
    usdtToken: Address;
    usdtTokenWallet: Address;
    saleToken: Address;
    saleTokenWallet: Address;
}
struct PaymentDetails {
    paymentWallet1: Address;
    paymentWallet2: Address;
    splitPercent: Int; 
}

inline fun getCustomPayload(): Cell {
    return beginCell().storeBool(false).endCell();
}

inline fun getForwardPayload(): Slice{
    return getCustomPayload().asSlice();
}

inline fun transferJettonWithGasValue(to: Address,
    value:Int,
    query_id: Int,
    amount: Int,
    destination: Address,
    responseDestination: Address) 
    {
        send(SendParameters{
            to: to,
            value: value,
            mode: SendPayGasSeparately,
            bounce: false,
            body: TokenTransfer{
                query_id: query_id,
                amount: amount,
                destination: destination,
                response_destination: responseDestination,
                custom_payload: getCustomPayload(),
                forward_ton_amount: 0,
                forward_payload: getForwardPayload()
            }.toCell()}
        );
}

inline fun transferJettonWithPayloadAndGasValue(to: Address,
    value:Int,
    query_id: Int,
    amount: Int,
    destination: Address,
    responseDestination: Address,
    forward_ton_amount: Int,
    forward_payload: Slice,
    custom_payload: Cell) 
    {
        send(SendParameters{
            to: to,
            value: value,
            mode: SendPayGasSeparately,
            bounce: false,
            body: TokenTransfer{
                query_id: query_id,
                amount: amount,
                destination: destination,
                response_destination: responseDestination,
                custom_payload: custom_payload,
                forward_ton_amount: forward_ton_amount,
                forward_payload: forward_payload
            }.toCell()}
        );
}