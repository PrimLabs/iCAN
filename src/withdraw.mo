import Result "mo:base/Result";
import C "mo:base/ExperimentalCycles";

shared({caller}) actor class CycleActor() = this{

    type canister_id = Principal;

    type Management = actor{
        deposit_cycles : shared { canister_id : canister_id } -> async ();
    };

    public func withdraw_cycles(to : ?Principal) : async (){
        let Lost = 10_000_000_000;
        let management : Management = actor("aaaaa-aa");
        if(C.balance() >= Lost){
            switch(to){
                case null {
                    C.add(C.balance() - Lost);
                    await management.deposit_cycles({ canister_id = caller })
                };
                case(?t){
                    C.add(C.balance() - Lost);
                    await management.deposit_cycles({ canister_id = t })
                }
            }
        }
    };

};