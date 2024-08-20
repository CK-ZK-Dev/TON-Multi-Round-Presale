import "@stdlib/deploy";
import "./messages/presaleV2/presale_v2_user_details_messages.tact";

struct UserPresaleDetails {
    owner: Address;
    usdtDeposit: Int;
    tonDeposit: Int;
    saleTokenPurchasedAmount: Int;
    claimed: Bool;
    isBlacklisted: Bool;
}

contract PresaleV2UserDetails with Deployable {
    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.011");
    claimed: Bool;
    isBlacklisted: Bool;
    usdtDeposit: Int;
    tonDeposit: Int;
    saleTokenPurchasedAmount: Int;
    owner: Address; // user contract address.
    master: Address; // parent contract address.
    
    // Initializes the contract.
    init(master: Address, owner: Address){
        self.usdtDeposit = 0;
        self.tonDeposit = 0;
        self.saleTokenPurchasedAmount = 0;
        self.owner = owner;
        self.master = master;
        self.claimed = false;
        self.isBlacklisted = false;
    }

    // Allows users to purchase token and purchase details are stored here.
    receive(msg: PurchaseToken){
        let ctx: Context = context();
        require(ctx.sender == self.master, "Only presale contract can call this");
        if (msg.usdtAmount != null) {
            self.usdtDeposit += msg.usdtAmount!!;
            emit(PurchaseUsingUSDT{
                    user: self.owner,
                    usdtAmount: msg.usdtAmount!!,
                    saleTokenPurchasedAmount: msg.saleTokenPurchasedAmount,
                    timestamp: now()
                }.toCell()
            );
        } else if (msg.tonAmount != null) {
            self.tonDeposit += msg.tonAmount!!;
            emit(PurchaseUsingTON{
                    user: self.owner,
                    tonAmount: msg.tonAmount!!,
                    saleTokenPurchasedAmount: msg.saleTokenPurchasedAmount,
                    timestamp: now()
                }.toCell()
            );
        }
        self.saleTokenPurchasedAmount += msg.saleTokenPurchasedAmount;
        //Send Excess token to user
        let msgValue: Int = self.msgValue(ctx.value);
        let fwdFee: Int = ctx.readForwardFee();
        msgValue -= fwdFee;
        transferTONByPayingGasSeparately(self.owner, msgValue, "refund-gas");
    }

    // Allows users to claim their token and updates the claim status.
    receive(msg: ClaimToken){
        // move all checks to a new function
        require(sender() == self.master, "Only presale contract can call this");
        require(self.claimed == false, "Already Claimed");
        require(!(self.isBlacklisted), "User Blacklisted");
        self.claimed = true;
        send(SendParameters{
                to: self.master,
                value: 0,
                mode: SendRemainingBalance,
                bounce: true,
                body: ClaimTokenInternal{
                    query_id: msg.query_id,
                    usdtAmount: self.usdtDeposit,
                    tonAmount: self.tonDeposit,
                    saleTokenAmount: self.saleTokenPurchasedAmount,
                    from: msg.from,
                    forward_ton_amount: msg.forward_ton_amount,
                    custom_payload: msg.custom_payload,
                    forward_payload: msg.forward_payload
                }.toCell()
            }
        );
    }

    // Receives UpdateBlacklistStatus message from Presales contract and updates the balcklist status of the user.
    receive(msg: UpdateBlacklistStatus){
        require(sender() == self.master, "Only presale contract can call this");
        self.isBlacklisted = msg.isBlacklisted;
        refundGasWithRemainingValue(sender()); 
    }

    // Function to help gas calculations before forwading a message.
    fun msgValue(value: Int): Int {
        let msgValue: Int = value;
        let tonBalanceBeforeMsg: Int = (myBalance() - msgValue);
        let storageFee: Int = (self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage));
        return (msgValue - (storageFee + self.gasConsumption));
    }

    // Function to get the presales user data.

    get fun user_presale_data(): UserPresaleDetails {
        return
            UserPresaleDetails{
                owner: self.owner,
                usdtDeposit: self.usdtDeposit,
                tonDeposit: self.tonDeposit,
                saleTokenPurchasedAmount: self.saleTokenPurchasedAmount,
                claimed: self.claimed,
                isBlacklisted: self.isBlacklisted
            };
    }

    // If claim token Internal message is failed, it will be received here.
    // sendRemaining Balance was used, so balance has to be increased on bounce.

    bounced(msg: bounced<ClaimTokenInternal>){
        let ctx: Context = context();
        self.claimed = false;
        let msgValue: Int = self.msgValue(ctx.value);
        let fwdFee: Int = ctx.readForwardFee();
        msgValue -= fwdFee;
        transferTONByPayingGasSeparately(self.owner, msgValue, "refund-gas");
    }
}
