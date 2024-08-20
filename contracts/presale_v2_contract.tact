import "@stdlib/deploy";
import "./messages/presaleV2/presale_v2_messages.tact";
import "./presale_v2_user_details.tact";
import "./resumable.tact";
import "./utils/presaleV2/presale_v2_helper.tact";


contract PresaleV2Contract with Deployable,Resumable {

    const minTonsForStorage: Int = ton("0.03");
    gasConsumption: Int = ton("0.011");
    owner: Address; // The Resumable trait requires you to add this exact state variable
    stopped: Bool;
    admin: Address;

    isInitialized: Bool;
    usdtToken: Address;
    usdtTokenWallet: Address;
    saleToken: Address;
    saleTokenWallet: Address;
    totalSold: Int;
    saleStartTime: Int;   
    saleClaimTime: Int;
    maxTokensInSinglePurchase: Int;

    saleTokenBalance: Int;
    paymentWallet1: Address;
    paymentWallet2: Address;
    splitPercent: Int; // 500 is 0.5 percentage

    tonPriceInUSD: Int;

    currentRound: Int;
    totalRounds: Int;
    usdRaised: Int;

    dynamicTimeFlag: Bool;

    rounds: map<Int, RoundDetails>;

    // Initialize the state variables
    init(owner: Address,
        usdtToken: Address,
        saleToken: Address,
        maxTokensInSinglePurchase: Int,
        saleStartTime: Int,
        admin: Address,
        paymentWallet1: Address,
        paymentWallet2: Address,
        splitPercent: Int,
        tonPriceInUSD: Int){
        require(tonPriceInUSD != 0, "Invalid TONPrice");
        self.owner = owner;
        self.usdtToken = usdtToken;
        self.usdtTokenWallet = usdtToken;
        self.saleToken = saleToken;
        self.saleTokenWallet = saleToken;
        self.maxTokensInSinglePurchase = maxTokensInSinglePurchase;
        self.saleStartTime = saleStartTime;
        self.admin = admin;
        self.paymentWallet1 = paymentWallet1;
        self.paymentWallet2 = paymentWallet2;
        self.splitPercent = splitPercent;
        self.tonPriceInUSD = tonPriceInUSD;
        self.saleClaimTime = 0;
        self.saleTokenBalance = 0;
        self.stopped = false;
        self.isInitialized = false;
        self.totalSold = 0;
        self.currentRound = 0;
        self.usdRaised = 0;
        self.dynamicTimeFlag = false;
        self.totalRounds = 0;
        self.rounds = emptyMap();

        emit(PaymentDetailsUpdated{
                paymentWallet1: self.paymentWallet1,
                paymentWallet2: self.paymentWallet2,
                splitPercent: self.splitPercent,
                owner: self.owner,
                timestamp: now()
            }.toCell()
        );
        emit(SaleTime{saleStartTime: saleStartTime}.toCell());
    }

    // Receiver to initialize the values of token wallets and set the rounds.
    receive(msg: InitializeTokenWalletsAndSetRounds){
        self.requireOwner();
        require(!(self.isInitialized), "already initilized");
        self.usdtTokenWallet = msg.usdtTokenWallet;
        self.saleTokenWallet = msg.saleTokenWallet;
        emit(InitializeTokenWallets{usdtTokenWallet: msg.usdtTokenWallet, saleTokenWallet: msg.saleTokenWallet}.toCell()
        );
        self.setRounds(msg.rounds,msg.totalRounds);
        self.totalRounds = msg.totalRounds;
        self.isInitialized = true;
        transferTONByPayingGasSeparately(self.owner, self.calculateMessageValue(context(), 1)-self.gasConsumption, "refund-gas");
    }

    // Receiver to purchase Token using USDT, price of USD is fixed to be 1 USD.
    // This receiver will get notified from the token side.
    receive(msg: TokenNotification){
        require(self.isInitialized, "Not initialized");   //If USDT won't be sent back if not initialized
        let ctx: Context = context();
        if (!(self.stopped)) {
            // Only if it's USDT, purchase has to be initiated.
            if (sender() == self.usdtTokenWallet) {
                self.purchaseUsingUSDT(msg, ctx);
            } else if (sender() == self.saleTokenWallet) {
                // Balance has to be updated.
                self.saleTokenBalance += msg.amount;
                transferTONByPayingGasSeparately(msg.sender, self.calculateMessageValue(context(), 1)-self.gasConsumption, "refund-gas");
            }
        } else {
            //Send jetton back to user
            transferJettonWithGasValue(ctx.sender,self.msgValueForJetton(ctx, 0, 3) - self.gasConsumption,msg.query_id,msg.amount,msg.sender,msg.sender);
        }
    }


    //To split TON Token
    receive(msg: TonPayment){
        require(self.isInitialized, "Not initialized");
        let ctx: Context = context();
        if (!(self.stopped)) {
            self.purchaseUsingTON(msg,ctx);  
        } else {
            transferTONByPayingGasSeparately(ctx.sender, self.calculateMessageValue(context(), 1) - self.gasConsumption, "contract-is-paused");
        }
    }

    // Receiver to claim tokens. Users can send Claim Token message.
    // Sale token will be sent to users, only after sale ends.
    receive(msg: ClaimToken){
        self.requireNotStopped();
        require(self.is_claim_time(), "Claim time has not started");
        let ctx: Context = context();
        require(ctx.sender == msg.from, "Invalid claimer!!!");
        let winit: StateInit = self.getPresaleUserDetailsInit(msg.from);
        send(SendParameters{
                to: contractAddress(winit),
                value: (self.calculateMessageValue(ctx, 5) - msg.forward_ton_amount),
                mode: SendPayGasSeparately,
                bounce: true,
                body: ClaimToken{
                    query_id: msg.query_id,
                    from: msg.from,
                    forward_ton_amount: msg.forward_ton_amount,
                    custom_payload: msg.custom_payload,
                    forward_payload: msg.forward_payload
                }.toCell()
            }
        );
    }

    receive(msg: UpdateSaleTokenBalance){
        self.requireOwner();
        require(msg.newSaleTokenBalance != 0, "Invalid amount");
        self.saleTokenBalance = msg.newSaleTokenBalance;
        emit(UpdateSaleTokenBalance{newSaleTokenBalance: msg.newSaleTokenBalance}.toCell());
    }

    // Receiver of Claim from  User's presale details contract.
    // It sends Token Transfer message to sale Token.
    receive(msg: ClaimTokenInternal){
        require(self.saleTokenBalance >= msg.saleTokenAmount, "Insufficient token in contract");
        let ctx: Context = context();
        let winit: StateInit = self.getPresaleUserDetailsInit(msg.from);
        require(ctx.sender == contractAddress(winit), "Only user wallet address can call this");
        self.saleTokenBalance -= msg.saleTokenAmount;
        emit(UserClaimed{user: msg.from, usdtAmount: msg.usdtAmount, tonAmount: msg.tonAmount, saleTokenAmount: msg.saleTokenAmount}.toCell());
        transferJettonWithPayloadAndGasValue(self.saleTokenWallet,
            (self.msgValueForJetton(ctx, msg.forward_ton_amount, 3) - self.gasConsumption),
            msg.query_id,
            msg.saleTokenAmount,
            msg.from,
            msg.from,
            msg.forward_ton_amount,
            msg.forward_payload,
            msg.custom_payload
        );
    }

    //TODO: Remove existing rounds
    // To chnage current round
    receive(msg: SetCurrentRound) {
        self.requireOwner();
        require(msg.newRound <= self.totalRounds,"Invalid Round");
        let newRoundDetails: RoundDetails = (self.rounds.get(msg.newRound))!!;
        newRoundDetails.startTime = now();
        self.rounds.set(msg.newRound,newRoundDetails);
        self.currentRound = msg.newRound;
        transferTONByPayingGasSeparately(self.owner, self.calculateMessageValue(context(), 1) - self.gasConsumption, "refund-gas");
    }

    //Increment rounds by Admin, if no purchase happens.
    receive("IncrementRound"){
        self.requireAdmin();
        self.incrementRound();
        transferTONByPayingGasSeparately(self.owner, self.calculateMessageValue(context(), 1) - self.gasConsumption, "refund-gas");
    }

    // To set/update the rounds details by Admin
    receive(msg: UpdateRound){
        self.requireOwner();
        self.rounds.set(msg.roundId,msg.round);
        transferTONByPayingGasSeparately(self.owner, self.calculateMessageValue(context(), 1) - self.gasConsumption, "refund-gas");
    }

    // To increase the rounds
    receive(msg: AddExtraRounds){
        self.requireOwner();
        self.setRounds(msg.rounds,msg.extraRounds);
        self.totalRounds += msg.extraRounds;
        transferTONByPayingGasSeparately(self.owner, self.calculateMessageValue(context(), 1) - self.gasConsumption, "refund-gas");
    }

    // To change the current owner of presales contract.
    receive(msg: ChangeOwner){
        self.requireOwner();
        self.owner = msg.newOwner;
        emit(ChangeOwner{queryId: msg.queryId, newOwner: msg.newOwner}.toCell());
        transferTONByPayingGasSeparately(self.owner, self.calculateMessageValue(context(), 1) - self.gasConsumption, "refund-gas");
    }

    // Updates the Admin address
    receive(msg: ChangeAdmin){
        self.requireOwner();
        self.admin =  msg.newAdmin;
        emit(ChangeAdmin{newAdmin:msg.newAdmin}.toCell());
        transferTONByPayingGasSeparately(self.owner, self.calculateMessageValue(context(), 1) - self.gasConsumption, "refund-gas");
    }

    // Updates the sale claim start time.
    receive(msg: ChangeSaleClaimTime){
        self.requireOwner();
        if (self.saleClaimTime != 0) {
            require(now() < self.saleClaimTime, "Claiming already started");
        }
        self.saleClaimTime = msg.saleClaimTime;
        emit(SaleClaimTime{
                saleStartTime: self.saleStartTime,
                saleClaimTime: self.saleClaimTime
            }.toCell()
        );
        transferTONByPayingGasSeparately(self.owner, self.calculateMessageValue(context(), 1) - self.gasConsumption, "refund-gas");
    }

    //Updates the gas consumption amount of the contract
    receive(msg: UpdateGasConsumption) {
        self.requireOwner();
        self.gasConsumption = msg.gasConsumption;
        transferTONByPayingGasSeparately(self.owner, self.calculateMessageValue(context(), 1) - self.gasConsumption, "refund-gas");
    }

    // To withdraw additional tokens in the contract.
    receive(msg: WithdrawTokens){
        let ctx: Context = context();
        self.requireOwner();
        require(msg.tokenWallet != self.saleTokenWallet, "cannot withdraw sale token");
        emit(TokensWithdrawn{
                token_wallet: msg.tokenWallet,
                amount: msg.amount,
                destination: msg.destination,
                owner: self.owner
            }.toCell()
        );
        transferJettonWithGasValue(msg.tokenWallet,
            self.msgValueForJetton(ctx, msg.forward_ton_amount, 4),
            msg.query_id,
            msg.amount,
            msg.destination,
            msg.response_destination
        );
    }

    // Updates the maximum tokens to sell.
    receive(msg: UpdateMaxTokensToBuy){
        self.requireOwner();
        self.maxTokensInSinglePurchase = msg.newMaxTokensInSinglePurchase;
        emit(UpdateMaxTokensToBuy{newMaxTokensInSinglePurchase: msg.newMaxTokensInSinglePurchase}.toCell());
        transferTONByPayingGasSeparately(self.owner, self.calculateMessageValue(context(), 1) -self.gasConsumption, "refund-gas");
    }

    // Blacklists/removes a user from blacklist. Should not fail if user has not made a purchase.
    receive(msg: UpdateBlacklistedStatusOfUser){  
        self.requireOwner();
        let winit: StateInit = self.getPresaleUserDetailsInit(msg.user);
        send(SendParameters{
                to: contractAddress(winit),
                value: (self.calculateMessageValue(context(), 2) - self.gasConsumption), // since gas consumption is deducted, fwd fee not considered
                mode: SendPayGasSeparately,
                bounce: false,
                body: UpdateBlacklistStatus{isBlacklisted: msg.isBlacklisted}.toCell(),
                code: winit.code,
                data: winit.data
            }
        );
    }

    //To update the payment details such as payment wallets and split percentage.
    receive(msg: UpdatePaymetDetails){
        self.requireOwner();
        self.paymentWallet1 = msg.paymentWallet1;
        self.paymentWallet2 = msg.paymentWallet2;
        self.splitPercent = msg.splitPercent;
        emit(PaymentDetailsUpdated{
                paymentWallet1: self.paymentWallet1,
                paymentWallet2: self.paymentWallet2,
                splitPercent: self.splitPercent,
                owner: self.owner,
                timestamp: now()
            }.toCell()
        );
    }


    // Updates the TON USD Price, no refund as minimal amount is used to update the value.
    receive(msg: UpdateTONPriceInUSD) {
        self.requireOwner();
        emit(TONPriceUpdated{
            oldTONPrice: self.tonPriceInUSD,
            newTONPrice: msg.newTONPrice,
            updatedTime: now()
        }.toCell());
        self.tonPriceInUSD = msg.newTONPrice;
    }

    //To Update Dynamic time flag value
    receive(msg: SetDynamicTimeFlag){
        self.requireOwner();
        self.dynamicTimeFlag = msg.set;
        transferTONByPayingGasSeparately(self.owner, self.calculateMessageValue(context(), 1) - self.gasConsumption, "refund-gas");
    }

    // Retreive the excess funds by the owner.
    receive("CloseFunds") {
        self.requireOwner();
        transferTONByPayingGasSeparately(self.owner, myBalance() - (2* self.gasConsumption + self.minTonsForStorage), "excess-funds");
    }

    fun purchaseUsingUSDT(msg: TokenNotification, ctx: Context) {
        let purchaseAmount: Int = self.amount_from_slice(msg.forward_payload);
        let amountToReturn: Int = msg.amount;
        let gas: Int = self.msgValueForJetton(ctx, 0, 3) - self.gasConsumption;
    
        // Check if sale condition is met
        if(self.checkSaleConditions(purchaseAmount) && self.checkAndUpdateRound()){
            let unSoldAmount: Int = self.unSoldTokensInRound(self.currentRound);
            if(unSoldAmount >= purchaseAmount){
                let totalUSDTRequired: Int =self.usdt_wrt_sale_token(purchaseAmount,self.currentRound);
                amountToReturn = self.updateRoundAndReturnExcess(msg.amount,totalUSDTRequired,unSoldAmount,purchaseAmount);
                if(amountToReturn != msg.amount){  //If enough tokens are present, usdt purchase is initiated.
                    gas = self.purchaseUsdtGasHelper(totalUSDTRequired,purchaseAmount,ctx,msg);
                }
            }else if(self.incrementRound()){ //As  long as next round exists, purchase is performed
                let unsoldAmountInNextRound: Int = self.unSoldTokensInRound(self.currentRound);
                let overlappePurchasedAmount: Int = purchaseAmount - unSoldAmount;
                if(unsoldAmountInNextRound >= overlappePurchasedAmount){
                    self.updateTotalSold(unSoldAmount,self.currentRound - 1);   // Increment total sold in prev round
                    let totalUSDTRequired: Int = self.usdt_wrt_sale_token(unSoldAmount,self.currentRound - 1) + self.usdt_wrt_sale_token(overlappePurchasedAmount,self.currentRound);
                    amountToReturn = self.updateRoundAndReturnExcess(msg.amount,totalUSDTRequired,unsoldAmountInNextRound,overlappePurchasedAmount);
                    if(amountToReturn != msg.amount){ 
                        gas = self.purchaseUsdtGasHelper(totalUSDTRequired,purchaseAmount,ctx, msg);
                    }
                }
            }
        }   

        // Transfers unused usdt amount back to user.
        if(gas == ctx.value){
            gas -= ( self.calculateMessageValue(ctx, 2) - self.gasRequiredForJettonTransfer(ctx,0) - self.gasConsumption);
            transferJettonWithGasValue(ctx.sender,gas,msg.query_id,msg.amount,msg.sender,msg.sender);
        }else if(amountToReturn != 0){
            transferJettonWithGasValue(ctx.sender,gas,msg.query_id,amountToReturn,msg.sender,msg.sender);
        }else{
            transferTONByPayingGasSeparately(msg.sender, gas, "excess-payment");
        }

    }

    fun purchaseUsingTON(msg:TonPayment, ctx: Context){
        let purchaseAmount: Int = self.amount_from_slice(msg.forward_payload);
        let amountToReturn: Int  = ctx.value;

        //Check  if sale condition is met
        if(self.checkSaleConditions(purchaseAmount) && self.checkAndUpdateRound()){
            let unSoldAmount: Int = self.unSoldTokensInRound(self.currentRound);
             if(unSoldAmount >= purchaseAmount){
                let totalTONRequired: Int =self.ton_wrt_sale_token(purchaseAmount,self.currentRound);
                let excessAmount: Int =  self.updateRoundAndReturnExcess(ctx.value,totalTONRequired,unSoldAmount,purchaseAmount);
                amountToReturn = self.purchaseTonGasHelper(totalTONRequired,purchaseAmount,ctx,excessAmount);
            }else if(self.incrementRound()) {  //As  long as next round exists, purchase is performed.
                let unsoldAmountInNextRound: Int = self.unSoldTokensInRound(self.currentRound);
                let overlappePurchasedAmount: Int = purchaseAmount - unSoldAmount;
                if(unsoldAmountInNextRound >= overlappePurchasedAmount){
                    self.updateTotalSold(unSoldAmount,self.currentRound - 1);   // Increment total sold in prev round
                    let totalTONRequired: Int = self.ton_wrt_sale_token(unSoldAmount,self.currentRound - 1) + self.ton_wrt_sale_token(overlappePurchasedAmount,self.currentRound);
                    let excessAmount: Int = self.updateRoundAndReturnExcess(ctx.value,totalTONRequired,unsoldAmountInNextRound,overlappePurchasedAmount);
                    amountToReturn = self.purchaseTonGasHelper(totalTONRequired,purchaseAmount,ctx,excessAmount);
                }
            }

        }

         if(amountToReturn != 0){
            transferTONByPayingGasSeparately(ctx.sender, amountToReturn, "excess-payment");
        }
    }


    //Calculates the excess amount of token user sent and updtae the total sold and increments the round if necessary.
    fun updateRoundAndReturnExcess(tokenAmount: Int, required: Int, unSold: Int, purchased: Int): Int {
        if(tokenAmount>=required){
            tokenAmount-= required;
            self.updateTotalSold(purchased,self.currentRound); // Increment total sold in current round
            if(unSold == purchased){
                self.incrementRound();
            }
        }
        return tokenAmount;
    }

    fun purchase(usdtAmount: Int?, tonAmount: Int?, saleTokenPurchaseAmount: Int,gasValue: Int, user: Address) {
        self.totalSold += saleTokenPurchaseAmount;
        let winit: StateInit = self.getPresaleUserDetailsInit(user);
        send(SendParameters{
                to: contractAddress(winit),
                value: gasValue, // since gas consumption is deducted, fwd fee not considered
                mode: SendPayGasSeparately,
                bounce: false,
                body: PurchaseToken{
                    query_id: 1008,
                    usdtAmount:usdtAmount,
                    tonAmount: tonAmount,
                    saleTokenPurchasedAmount: saleTokenPurchaseAmount
                }.toCell(),
                code: winit.code,
                data: winit.data
            }
        );
    }

    fun purchaseUsdtGasHelper(usdtAmount: Int, saleTokenPurchaseAmount: Int,ctx: Context, msg: TokenNotification): Int {
        let msgValueAfterPresaleDeduction: Int = (self.calculateMessageValue(ctx, 4) - 5 * self.gasConsumption);
        let valueRequiredForJettonTransfer: Int = self.gasRequiredForJettonTransfer(ctx, 4);
        if(msgValueAfterPresaleDeduction <= valueRequiredForJettonTransfer * 2){
            //No enough gas to complete the txn, so token will be sent back to user
            return ctx.value;
        }
        let gasValue: Int = (msgValueAfterPresaleDeduction - valueRequiredForJettonTransfer * 3) / 4;
        self.usdRaised += usdtAmount * 1000;
        self.purchase(usdtAmount,null,saleTokenPurchaseAmount,gasValue,msg.sender);
        let jettonGas: Int = (gasValue+valueRequiredForJettonTransfer);
        self.splitUSDT(msg,usdtAmount,jettonGas);
        return jettonGas;
       
    }

    fun purchaseTonGasHelper(tonAmount: Int, saleTokenPurchaseAmount: Int,ctx: Context, excessAmount: Int): Int {
        if(excessAmount != ctx.value){
            let balanceContractmsgValueRequired: Int = 7 * self.gasConsumption;
            let msgValueAfterPresaleDeduction: Int = (self.calculateMessageValue(ctx, 0) - balanceContractmsgValueRequired - tonAmount);
            if(excessAmount  <= msgValueAfterPresaleDeduction){
                // Return to user if there is no enough TON to process request.
                return (self.calculateMessageValue(ctx, 1) - self.gasConsumption); 
            } 
            self.usdRaised += (tonAmount * self.tonPriceInUSD)/ ton("1");
            self.purchase(null,tonAmount,saleTokenPurchaseAmount, 3 * self.gasConsumption, ctx.sender);
            self.splitTON(tonAmount);
            return msgValueAfterPresaleDeduction;
        }else{
            let gas: Int = self.calculateMessageValue(ctx, 1) - self.gasConsumption;
            return gas;
        }
        
    }

    // Function to split the USD token between payment wallets.
    fun splitUSDT(msg: TokenNotification, usdtAmount: Int,remainingValue: Int) {
        let splitAmount1: Int = usdtAmount * self.splitPercent / (1000 * 100);
        let splitAmount2: Int = (usdtAmount - splitAmount1);
        transferJettonWithGasValue(self.usdtTokenWallet,remainingValue,msg.query_id,splitAmount1,self.paymentWallet1,msg.sender);
        transferJettonWithGasValue(self.usdtTokenWallet,remainingValue,msg.query_id,splitAmount2,self.paymentWallet2,msg.sender);
    }

    // Function to help gas calculations for jetton before forwading a message.
    fun splitTON(msgValue: Int) {
        let splitAmount1: Int = msgValue * self.splitPercent / (1000 * 100);
        let splitAmount2: Int = (msgValue - splitAmount1);
        transferTONByPayingGasSeparately(self.paymentWallet1, splitAmount1, "ton-payment");
        transferTONByPayingGasSeparately(self.paymentWallet2, splitAmount2, "ton-payment");
    }

    // Function to increment current round based on time.
    fun checkAndUpdateRound(): Bool {
        if(self.currentRound == 0){    
            self.incrementRound();
            return true;
        }
        if(now() > self.round_end_time(self.currentRound)){
            let incremented: Bool = self.incrementRound();
            return incremented;
        }else{
            return true;
        }
        
    }

    //Updates the total sold in a particularround.
    fun updateTotalSold(amount: Int, round: Int) {
        let roundDetails: RoundDetails = self.rounds.get(round)!!;
        roundDetails.totalSoldInCurrentRound += amount;
        self.rounds.set(round,roundDetails);
    }

    // Increments the current round
    fun incrementRound(): Bool{
        if(self.currentRound < self.totalRounds){
            let newRoundDetails: RoundDetails = (self.rounds.get(self.currentRound+1))!!;
            newRoundDetails.startTime = now();
            if(self.currentRound != 0 && !self.dynamicTimeFlag){
                let currentRoundEndTime: Int = self.round_end_time(self.currentRound);
                if(currentRoundEndTime > now()){
                    newRoundDetails.entireDuration += (currentRoundEndTime - now());
                }
            }
            self.currentRound += 1;
            self.rounds.set(self.currentRound,newRoundDetails);
            return true;
        }else{
            return false;
        }
    }

    //Replace/set a round based on round Id
    fun setRounds(rounds: map<Int, RoundDetails>,totalRounds: Int){
        let i: Int = self.totalRounds + 1;
        repeat(totalRounds) {
            self.rounds.set(i,rounds.get(i));
            i += 1;
        }
    }

    // Function to check if sale is happening and sale conditions are met.
    fun checkSaleConditions(purchaseAmount: Int): Bool {
        require(self.is_sale_time(), "Sale not happening"); 
        require(purchaseAmount >=0, "Invalid purchase amount");
        if(purchaseAmount <= self.maxTokensInSinglePurchase){
            return true;
        }
        return false;
    }

    //Function to calculate the gas required forjetton transfers and returns th gas amount.
    fun msgValueForJetton(ctx: Context, forward_ton_amount: Int, fwdTimes: Int): Int {
        let valueAfterPresaleDeduction: Int = self.calculateMessageValue(ctx, fwdTimes);
        //Calculation in Jetton contract.
        let final: Int = self.gasRequiredForJettonTransfer(ctx, forward_ton_amount);
        require(valueAfterPresaleDeduction > final, "Not enough gas for jetton transfer");
        return (valueAfterPresaleDeduction - forward_ton_amount);
    }

    // Deducts gas required from the incoming message value
    fun calculateMessageValue(ctx: Context, fwdTimes: Int): Int {
        let msgValue: Int = ctx.value;
        let fwdFee: Int = ctx.readForwardFee() * fwdTimes;
        let tonBalanceBeforeMsg: Int = (myBalance() - msgValue);
        let storageFee: Int = (self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage));
        return (msgValue - ((storageFee + self.gasConsumption) + fwdFee));
    }

    fun gasRequiredForJettonTransfer(ctx: Context, forward_ton_amount: Int): Int {
        return (((2 * self.gasConsumption + self.minTonsForStorage) + ctx.readForwardFee() * 2) + forward_ton_amount);
    }

    // Function to get presales contract details of each user.
    fun getPresaleUserDetailsInit(address: Address): StateInit {
        return initOf PresaleV2UserDetails(myAddress(), address);
    }

    fun tokenAmountWrtRound(purchaseAmount: Int,round: Int, isUSDT: Bool): Int {
        let tokenAmount: Int = isUSDT ? self.usdt_wrt_sale_token(purchaseAmount,round) : self.ton_wrt_sale_token(purchaseAmount,round);
        return tokenAmount;
    }

    //Helper function to calculate purchase token  required.
    fun calculateTokenRequired(purchaseAmount: Int,isUSDT: Bool): Int{
        if(purchaseAmount > self.maxTokensInSinglePurchase){
            return 0;
        }

        let currentRound: Int = (self.currentRound == 0 || now() > self.round_end_time(self.currentRound)) ? self.currentRound+1 : self.currentRound;
        let unSoldAmount: Int = self.unSoldTokensInRound(currentRound);
        if(unSoldAmount >= purchaseAmount){
            let amount: Int = self.tokenAmountWrtRound(purchaseAmount,currentRound, isUSDT);
            return amount;
        }else if(currentRound == self.totalRounds){
            return 0;
        }else{
            let unsoldAmountInNextRound: Int = self.unSoldTokensInRound(currentRound + 1);
            let overlappePurchasedAmount: Int = purchaseAmount - unSoldAmount;
            if(unsoldAmountInNextRound >= overlappePurchasedAmount){
                let amount: Int = (self.tokenAmountWrtRound(unSoldAmount,currentRound,isUSDT) + self.tokenAmountWrtRound(overlappePurchasedAmount,currentRound + 1,isUSDT)); 
                return amount;
            }else{
                return 0;
            }
        }
    }

    fun requireAdmin(){
       nativeThrowUnless(132, sender() == self.admin); 
    }

    // Returns USDT required for a given amount of sale token. Returns 0, if purchase cannot be completed.
    get fun usdt_required(purchaseAmount: Int): Int{
        let usdtRequired: Int = self.calculateTokenRequired(purchaseAmount, true);
        return usdtRequired;
    }

    // Returns TON required for a given amount of sale token. Returns 0, if purchase cannot be completed.
    get fun ton_required(purchaseAmount: Int): Int{
        let tonRequired: Int = self.calculateTokenRequired(purchaseAmount, false);
        return tonRequired;
    }


    //Sale Token Amount is In 10^9, returns USDT required for sale in 10^6
    get fun usdt_wrt_sale_token(saleTokenAmount: Int, currentRound: Int): Int {
        let saleTokenPrice: Int = self.rounds.get(currentRound)!!.tokenPrice;
        return saleTokenAmount * saleTokenPrice / ton("1000"); 
    }

    //Sale Token Amount is In 10^9, returns TON required for sale in 10^9
    get fun ton_wrt_sale_token(saleTokenAmount: Int, currentRound: Int): Int {
        let saleTokenPrice: Int = self.rounds.get(currentRound)!!.tokenPrice;
        return ((saleTokenAmount * saleTokenPrice) / self.tonPriceInUSD) ;
    }

    //Function to calculate unsold tokens in a particular round.
    get fun unSoldTokensInRound(round: Int): Int {
        return (self.rounds.get(round)!!.maxTokensToSell - self.rounds.get(round)!!.totalSoldInCurrentRound);
    }

    //Function to get amount from forward payload.
    get fun amount_from_slice(payload: Slice): Int {
        try{
            return payload.loadInt(256);
        }catch(err){
            return 0;
        }
    }

    // Function to get contract address of presales details of user.
    get fun presale_user_details_address(owner: Address): Address {
        let winit: StateInit = self.getPresaleUserDetailsInit(owner);
        return contractAddress(winit);
    }

    // Function to get the sales details.
    get fun sales_details(): SalesDetails {
        return
            SalesDetails{
                maxTokensInSinglePurchase: self.maxTokensInSinglePurchase,
                totalSold: self.totalSold,
                saleStartTime: self.saleStartTime,
                saleClaimTime: self.saleClaimTime,
                saleTokenBalance: self.saleTokenBalance,
                currentRound: self.currentRound,
                totalRounds:self.totalRounds,
                usdRaised: self.usdRaised
            };
    }

    // Function to get the tokens and token wallets
    get fun token_details_in_contract(): TokenDetails {
        return
            TokenDetails{
                usdtToken: self.usdtToken,
                usdtTokenWallet: self.usdtTokenWallet,
                saleToken: self.saleToken,
                saleTokenWallet: self.saleTokenWallet
            };
    }

    // Function returns Boolean based on claim time.
    get fun is_claim_time(): Bool {
        if(self.saleClaimTime > 0 && now() >= self.saleClaimTime){
            return true;
        }
        return false;
    }

    // Function returns Boolean based on sale time.
    get fun is_sale_time(): Bool {
        return now() >= self.saleStartTime;
    }

    //Returns the details of a round based on round Id
    get fun round_data(round: Int): RoundDetails {
        return self.rounds.get(round)!!;
    }

    //Returns the end time of a round based on round Id.
    get fun round_end_time(round: Int): Int {
        try{
            let roundDetails: RoundDetails = self.rounds.get(round)!!;
            return (roundDetails.startTime + roundDetails.entireDuration);
        }catch(err){
            return 0;
        }
    }

    get fun ton_price_in_usd(): Int {
        return self.tonPriceInUSD;
    }

}