import Types "Lib/Types";
import Result "mo:base/Result";

actor Service {

    type Canister = Types.Canister;
    type DeployArgs = Types.DeployArgs;
    type Error = Types.Error;
    type Status = Types.Status;
    type TransformArgs = Types.TransformArgs;
    type UpdateSettingsArgs = Types.UpdateSettingsArgs;

    // iCAN Canister Public Service Interface
    public type iCAN = actor{

        // get your own hubs' info (call this function use your identity)
        // @return array of (Hub Name, Hub Canister Id)
        getHub : query () -> async [(Text, Principal)];

        // get current hub wasm and cycle withdraw wasm in use
        // @return (hub wasm, cycle withdraw wasm)
        getWasms : query () -> async ([Nat8], [Nat8]);

        // get administrators of ican at present
        // @return array of administrators
        getAdministrators : query () -> async [Principal];

        // create canister management hub
        // @param name : hub name
        // @param amount : icp e8s amount
        createHub : (name : Text, amount : Nat64) -> async Result.Result<Principal, Error>;

        // add hub info to your hubs
        // @param name : hub name
        // @param hub_id : hub canister principal
        addHub : (name : Text, hub_id : Principal) -> async Text;

        // delete hub from your hub set
        deleteHub : (hub_id : Principal) -> async Result.Result<(), Error>;

        // transform icp to cycles and deposit the cycles to target cansiter
        transformIcp : (args : TransformArgs) -> async Result.Result<(), Error>;

    };

    public type Hub = actor{

        // get current version hub canister's wasm
        // @return Wasm Version
        getVersion : query() -> async Nat;

        // get owners of this hub canister
        // @return owners array
        getOwners : query() -> async [Principal];

        // get status of hub canister ( owner only )
        getStatus : query() -> async Result.Result<Status, Error>;

        // get canisters managed by this hub ( owner only )
        getCanisters : query() -> async Result.Result<[Canister], Error>;

        // get wasm of specified canister ( owner only )
        getWasm : query (canister_id : Principal) -> async Result.Result<[Nat8], Error>;

        // put canister into hub ( not matter if not controlled by hub canister ) ( owner only )
        // @param c : should be put into hub canister
        putCanister : (c : Canister) -> async Result.Result<(), Error>;

        // deploy canister by hub canister  ( owner only )
        // @return #ok(new canister's principal) or #err(Error)
        deployCanister : (args : DeployArgs) -> async Result.Result<Principal, Error>;

        // update canister settings  ( owner only )
        updateCanisterSettings : (args : UpdateSettingsArgs) -> async Result.Result<(), Error>;

        // start the specify canister, which should be controlled by hub canister  ( owner only )
        // @param principal : target canister's principal
        startCanister : (principal : Principal) -> async Result.Result<(), Error>;

        // stop canister ( owner only )
        // @param principal : target canister's principal
        stopCanister : (principal : Principal) -> async Result.Result<(), Error>;

        // deposit cycles to target canister ( equal to top up to target canister)
        // @param id : target canister principal, cycle amount : how much cycles should be top up
        depositCycles(id : Principal, cycle_amount : Nat, ) : async Result.Result<(), Error>;

        // delete canister from hub canister and withdraw cycles from it ( owner only )
        // @param canister's principal
        delCaniste : ( id : Principal ) -> async Result.Result<(), Error>;

        // install cycle wasm to hub canister ( owner only )
        // @param wasm : cycle wasm blob (you can deploy your own cycle wasm to your hub canister)
        installCycleWasm : (wasm : [Nat8]) -> async Result.Result<(), Error>;

        // change hub owner ( owner only )
        // @param : new owners array
        changeOwner : (newOwners : [Principal]) -> async Result.Result<(), Error>;

    };

}