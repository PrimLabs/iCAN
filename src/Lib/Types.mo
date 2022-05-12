import Time "mo:base/Time";
import Result "mo:base/Result";

module{

    /// iCAN Types

    public type Error = {
        #Invalid_Caller;
        #Invalid_CanisterId;
        #No_Wasm;
        #No_Record;
        #Insufficient_Cycles;
        #Ledger_Transfer_Failed : Nat; // value : log id
        #Create_Canister_Failed : Nat;
    };

    public type Canister = {
        name : Text;
        description : Text;
        canister_id : Principal;
        wasm : ?[Nat8];
    };

    public type Status = {
        cycle_balance : Nat;
        memory : Nat;
    };

    public type UpdateSettingsArgs = {
        canister_id : Principal;
        settings : canister_settings
    };

    public type TransformArgs = {
        icp_amount : Nat64; // e8s
        to_canister_id : Principal
    };

    /// Hub Types

    public type HubInterface = actor{
        init : (owner : Principal, cycle_wasm : [Nat8]) -> async ();
    };

    public type DeployArgs = {
        name : Text;
        description : Text;
        settings : ?canister_settings;
        deploy_arguments : ?[Nat8];
        wasm : ?[Nat8];
        cycle_amount : Nat;
        preserve_wasm : Bool;
    };

    public type CycleInterface = actor{
        withdraw_cycles : () -> async ();
    };

    /// Management Types

    public type canister_id = Principal;

    public type wasm_module = [Nat8];

    public type canister_settings = {
        freezing_threshold : ?Nat;
        controllers : ?[Principal];
        memory_allocation : ?Nat;
        compute_allocation : ?Nat;
    };

    public type definite_canister_settings = {
        controllers : [Principal];
        compute_allocation : Nat;
        memory_allocation : Nat;
        freezing_threshold : Nat;
    };

    public type CanisterStatus = {
        status : { #running; #stopping; #stopped };
        settings: definite_canister_settings;
        module_hash: ?Blob;
        memory_size: Nat;
        cycles: Nat;
    };

    public type Management = actor {
        delete_canister : shared { canister_id : canister_id } -> async ();
        deposit_cycles : shared { canister_id : canister_id } -> async ();
        start_canister : shared { canister_id : canister_id } -> async ();
        stop_canister : shared { canister_id : canister_id } -> async ();
        install_code : shared {
            arg : [Nat8];
            wasm_module : wasm_module;
            mode : { #reinstall; #upgrade; #install };
            canister_id : canister_id;
            } -> async ();
        create_canister : shared { settings : ?canister_settings } -> async {
            canister_id : canister_id;
        };
        update_settings : ({
            canister_id : Principal;
            settings : canister_settings
        }) -> async ();
        canister_status : ({canister_id : canister_id}) -> async ({
            status : { #running; #stopping; #stopped };
            settings: definite_canister_settings;
            module_hash: ?Blob;
            memory_size: Nat;
            cycles: Nat;
            freezing_threshold: Nat;
        });

    };

    /// Ledger Types

    public type Memo = Nat64;

    public type Token = {
        e8s : Nat64;
    };

    public type TimeStamp = {
        timestamp_nanos: Nat64;
    };

    public type AccountIdentifier = Blob;

    public type SubAccount = Blob;

    public type BlockIndex = Nat64;

    public type TransferError = {
        #BadFee: {
            expected_fee: Token;
        };
        #InsufficientFunds: {
            balance: Token;
        };
        #TxTooOld: {
            allowed_window_nanos: Nat64;
        };
        #TxCreatedInFuture;
        #TxDuplicate : {
            duplicate_of: BlockIndex;
        };
    };

    public type TransferArgs = {
        memo: Memo;
        amount: Token;
        fee: Token;
        from_subaccount: ?SubAccount;
        to: AccountIdentifier;
        created_at_time: ?TimeStamp;
    };

    public type TransferResult = {
        #Ok: BlockIndex;
        #Err: TransferError;
    };

    public type Address = Blob;

    public type AccountBalanceArgs = {
        account : Address
    };

    public type NotifyCanisterArgs = {
        // The of the block to send a notification about.
        block_height: BlockIndex;
        // Max fee, should be 10000 e8s.
        max_fee: Token;
        // Subaccount the payment came from.
        from_subaccount: ?SubAccount;
        // Canister that received the payment.
        to_canister: Principal;
        // Subaccount that received the payment.
        to_subaccount:  ?SubAccount;
    };

    public type Ledger = actor{
        transfer : TransferArgs -> async TransferResult;
        account_balance : query AccountBalanceArgs -> async Token;
        notify_dfx : NotifyCanisterArgs -> async ();
    };

    /// CMC Types

    type NotifyError = {
        #Refunded : {
            reason : Text;
            block_index : ?BlockIndex;
        };
        #Processing;
        #TransactionTooOld : BlockIndex;
        #InvalidTransaction : Text;
        #Other : { error_code : Nat64; error_message : Text };
    };

    type NotifyTopUpResult = {
      #Ok : Nat;
      #Err : NotifyError;
    };

    type NotifyTopUpArg = {
      block_index : BlockIndex;
      canister_id : Principal;
    };

    type NotifyCreateCanisterResult = {
      #Ok : Principal;
      #Err : NotifyError;
    };

    type NotifyCreateCanisterArg = {
      block_index : Nat64;
      controller : Principal;
    };

    public type CMC = actor{
        notify_top_up : (NotifyTopUpArg) -> async (NotifyTopUpResult);
        notify_create_canister : (NotifyCreateCanisterArg) -> async (NotifyCreateCanisterResult);
    };

    // Emergency Types

    public type EmergencyArgs = {
        #ledger_transfer : (Principal, Nat64, Text);
        #create_canister : (Principal, Nat64, Text); // user's principal, transfer blohck index, hub name
    };

};