import Time "mo:base/Time";
import Result "mo:base/Result";

module{

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

    public type DeployArgs = {
        name : Text;
        description : Text;
        settings : ?canister_settings;
        deploy_arguments : ?[Nat8];
        wasm : ?[Nat8];
        cycle_amount : Nat;
        preserve_wasm : Bool;
    };

    public type canister_settings = {
        freezing_threshold : ?Nat;
        controllers : ?[Principal];
        memory_allocation : ?Nat;
        compute_allocation : ?Nat;
    };

};