import Array "mo:base/Array";
import Account "Lib/Account";
import Blob "mo:base/Blob";
import Bucket "Lib/Bucket";
import Cycles "mo:base/ExperimentalCycles";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Prim "mo:⛔";
import Result "mo:base/Result";
import TrieMap "mo:base/TrieMap";
import Time "mo:base/Time";
import TrieSet "mo:base/TrieSet";
import Types "Lib/Types";

shared(installer) actor class hub() = this{

    type Error = Types.Error;
    type Canister = Types.Canister;
    type Status = Types.Status;
    type canister_id = Types.canister_id;
    type wasm_module = Types.wasm_module;
    type Management = Types.Management;
    type Ledger = Types.Ledger;
    type DeployArgs = Types.DeployArgs;
    type CycleInterface = Types.CycleInterface;
    type UpdateSettingsArgs = Types.UpdateSettingsArgs;
    let CYCLE_MINTING_CANISTER = Principal.fromText("rkp4c-7iaaa-aaaaa-aaaca-cai");
    let ledger : Ledger = actor("ryjl3-tyaaa-aaaaa-aaaba-cai");
    let management : Management = actor("aaaaa-aa");
    stable var owners : TrieSet.Set<Principal> = TrieSet.fromArray<Principal>([installer.caller], Principal.hash, Principal.equal);
    stable var cycle_wasm : [Nat8] = [];
    stable var canisters_entries : [(Principal, Canister)] = [];
    var canisters : TrieMap.TrieMap<Principal, Canister> = TrieMap.fromEntries(canisters_entries.vals(), Principal.equal, Principal.hash);
    let CURRENT_VERSION : Nat = 0;

    public query func getVersion() : async Nat{
        CURRENT_VERSION
    };

    public query func getOwners() : async [Principal]{
        TrieSet.toArray<Principal>(owners)
    };

    public query({caller}) func getStatus() : async Result.Result<Status, Error>{
        if(not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)){
            return #err(#Invalid_Caller)
        };
        #ok({
            cycle_balance = Cycles.balance();
            memory = Prim.rts_memory_size()
        })
    };

    public query({caller}) func getCanisters() : async Result.Result<[Canister], Error>{
        if(not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)){ return #err(#Invalid_Caller) };
        var res = Array.init<Canister>(canisters.size(), {
            name = "";
            description = "";
            canister_id = Principal.fromActor(this);
            wasm = null;
        });
        var index = 0;
        for(c in canisters.vals()){
            res[index] := {
                name = c.name;
                description = c.description;
                canister_id = c.canister_id;
                wasm = null;
            };
            index := index + 1;
        };
        #ok(Array.freeze<Canister>(res))
    };

    public query({caller}) func getWasm(canister_id : Principal) : async Result.Result<[Nat8], Error>{
        if(not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)){
            return #err(#Invalid_Caller)
        };
        switch(canisters.get(canister_id)){
            case null { #ok([]) };
            case(?c){
                switch(c.wasm){
                    case null { #err(#No_Wasm) };
                    case(?wasm){ #ok(wasm) }
                }
            }
        }
    };

    // put & change
    public shared({caller}) func putCanister(c : Canister) : async Result.Result<(), Error>{
        if(not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)){
            return #err(#Invalid_Caller)
        };
        canisters.put(c.canister_id, c);
        #ok(())
    };

    public shared({caller}) func deployCanister(
        args : DeployArgs
    ) : async Result.Result<Principal, Error>{
        if(not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)){
            return #err(#Invalid_Caller)
        };
        // 100 000 000 000 Cycle (0.1 T) is used to keep hub available
        if(args.cycle_amount + 100_000_000_000 >= Cycles.balance() or args.cycle_amount < 200_000_000_000){
            return #err(#Insufficient_Cycles)
        };
        Cycles.add(args.cycle_amount);
        let _canister_id = (await management.create_canister({ settings = args.settings })).canister_id;
        canisters.put(_canister_id, {
            name = args.name;
            description = args.description;
            canister_id = _canister_id;
            wasm = if(args.preserve_wasm){ args.wasm } else { null };
        });
        ignore do?{
            if(args.wasm!.size() != 0){
                ignore await management.install_code({
                    arg = [];
                    wasm_module = args.wasm!;
                    mode = #install;
                    canister_id = _canister_id;
                });
            }
        };
        ignore do?{
            ignore await management.update_settings({
                canister_id = _canister_id;
                settings = args.settings!;
            });
        };
        #ok(_canister_id)
    };

    public shared({caller}) func updateCanisterSettings(args : UpdateSettingsArgs) : async Result.Result<(), Error> {
        if(not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)){
            return #err(#Invalid_Caller)
        };
        ignore await management.update_settings({
            canister_id = args.canister_id;
            settings = args.settings
        });
        #ok(())
    };

    public shared({caller}) func startCanister(principal : Principal) : async Result.Result<(), Error> {
        if(not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)){
            return #err(#Invalid_Caller)
        };
        ignore await management.start_canister({ canister_id = principal});
        #ok(())
    };

    public shared({caller}) func stopCanister(principal : Principal) : async Result.Result<(), Error> {
        if(not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)){
            return #err(#Invalid_Caller)
        };
        await management.stop_canister({ canister_id = principal});
        #ok(())
    };

    public shared({caller}) func depositCycles(
        id : Principal,
        cycle_amount : Nat,
    ) : async Result.Result<(), Error>{
        if(not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)){
            return #err(#Invalid_Caller)
        };
        if(cycle_amount + 100_000_000_000 >= Cycles.balance()){
            return #err(#Insufficient_Cycles)
        };
        Cycles.add(cycle_amount);
        ignore await management.deposit_cycles({ canister_id = id });
        #ok(())
    };

    public shared({caller}) func delCanister(
        id : Principal
    ) : async Result.Result<(), Error>{
        if(not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)){
            return #err(#Invalid_Caller)
        };
        ignore await management.start_canister({ canister_id = id });
        ignore await management.install_code({
            arg = [];
            wasm_module = cycle_wasm;
            mode = #reinstall;
            canister_id = id;
        });
        let from : CycleInterface = actor(Principal.toText(id));
        await from.withdraw_cycles();
        ignore await management.stop_canister({ canister_id = id });
        ignore await management.delete_canister({ canister_id = id });
        canisters.delete(id);
        #ok(())
    };

    public shared({caller}) func installCycleWasm(wasm : [Nat8]) : async Result.Result<(), Error>{
        if(not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)){
            return #err(#Invalid_Caller)
        };
        cycle_wasm := wasm;
        #ok(())
    };

    public shared({caller}) func changeOwner(newOwners : [Principal]) : async Result.Result<(), Error>{
        if(not TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal)){
            return #err(#Invalid_Caller)
        };
        owners := TrieSet.fromArray<Principal>(newOwners, Principal.hash, Principal.equal);
        #ok(())
    };

    // ican calls this function when creating this hub
    public shared({caller}) func init(owner : Principal, _cycle_wasm : [Nat8]) : async (){
        assert(TrieSet.mem<Principal>(owners, caller, Principal.hash(caller), Principal.equal));
        owners := TrieSet.fromArray<Principal>([owner], Principal.hash, Principal.equal);
        cycle_wasm := _cycle_wasm;
    };

    public func wallet_receive() : async (){
        ignore Cycles.accept(Cycles.available())
    };

    system func preupgrade(){
        canisters_entries := Iter.toArray(canisters.entries());
    };

    system func postupgrade(){
        canisters_entries := [];
    };

};