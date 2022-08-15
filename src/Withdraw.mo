import C "mo:base/ExperimentalCycles";
import Result "mo:base/Result";

shared({caller}) actor class CycleActor() = this{

    type Management = actor{
        deposit_cycles : shared { canister_id : Principal } -> async ();
    };

    // withdraw cycles to hub canister
    public func withdraw_cycles(canister_id : Principal) : async (){
        let Lost = 10_000_000_000;
        let management : Management = actor("aaaaa-aa");
        if(C.balance() >= Lost){
            C.add(C.balance() - Lost);
            await management.deposit_cycles({ canister_id = canister_id })
        }
    };

};