import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Cycles "mo:base/ExperimentalCycles";
import Array "mo:base/Array";
import TrieMap "mo:base/TrieMap";
import Time "mo:base/Time";
import Prim "mo:⛔";
import Iter "mo:base/Iter";
import Account "Lib/Account";
import Blob "mo:base/Blob";
import Types "Lib/Types";

shared(installer) actor class hub() = this{

    private type Error = Types.Error;

    private type Canister = Types.Canister;

    private type Record = Types.Record;

    private type Status = Types.Status;

    stable var record_entries : [(Principal,[Record])] = [];
    var records : TrieMap.TrieMap<Principal,[Record]> = TrieMap.fromEntries(record_entries.vals(), Principal.equal, Principal.hash);

    stable var owner : Principal = installer.caller;
    stable var canisters_entries : [(Principal, Canister)] = [];
    var canisters : TrieMap.TrieMap<Principal, Canister> = TrieMap.fromEntries(canisters_entries.vals(), Principal.equal, Principal.hash);

    public shared({caller}) func changeOwner(newOwner : Principal) : async Result.Result<(), Error>{
        if(caller == owner){
            owner := newOwner;
            #ok()
        }else{
            #err(#Invalid_Caller)
        }
    };

    public query func getOwner() : async Principal{
        owner
    };

    stable var cycle_wasm : [Nat8] = [];

    public shared({caller}) func installCycleWasm(wasm : [Nat8]) : async (){
        if(caller == owner){
            cycle_wasm := wasm
        }
    };



    public query({caller}) func getStatus() : async Result.Result<Status, Error>{
        if(caller != owner){
            return #err(#Invalid_Caller)
        };
        #ok({
            cycle_balance = Cycles.balance();
            memory = Prim.rts_memory_size()
        })
    };

    public query({caller}) func getCanisters() : async Result.Result<[Canister], Error>{
        if(caller != owner){
            return #err(#Invalid_Caller)
        };
        var res = Array.init<Canister>(canisters.size(), {
            name = "";
            description = "";
            canister_id = Principal.fromActor(this);
            wasm = null;
        });
        var index = 0;
        for(c in canisters.vals()){
            res[index] := c;
            index := index + 1;
        };
        #ok(Array.freeze<Canister>(res))
    };

    public query({caller}) func getRecords(p : Principal) : async Result.Result<[Record], Error>{
        if(caller != owner){
            return #err(#Invalid_Caller)
        };
        switch(records.get(p)){
            case null { #err(#No_Record)};
            case (?r) {
                #ok(r)
            }
        };

    };

    public query({caller}) func getWasm(canister_id : Principal) : async Result.Result<[Nat8], Error>{
        if(caller != owner){
            return #err(#Invalid_Caller)
        };
        switch(canisters.get(canister_id)){
            case null { #err(#Invalid_CanisterId) };
            case(?c){
                switch(c.wasm){
                    case null { #err(#No_Wasm) };
                    case(?wasm){
                        #ok(wasm)
                    }
                }
            }
        }
    };

    // put & change
    public shared({caller}) func putCanister(c : Canister) : async Result.Result<(), Error>{
        if(caller != owner){
            return #err(#Invalid_Caller)
        };
        canisters.put(c.canister_id, c);
        #ok(())
    };

    private type canister_id = Types.canister_id;

    private type wasm_module = Types.wasm_module;

    private type canister_settings = Types.canister_settings;

    private type Management = Types.Management;

    private type Memo = Types.Memo;

    private type Token = Types.Token;

    private type TimeStamp = Types.TimeStamp;

    private type AccountIdentifier = Types.AccountIdentifier;

    private type SubAccount = Types.SubAccount;

    private type BlockIndex = Types.BlockIndex;

    private type TransferError = Types.TransferError;

    private type TransferArgs = Types.TransferArgs;

    private type TransferResult = Types.TransferResult;

    private type Address = Types.Address;

    private type AccountBalanceArgs = Types.AccountBalanceArgs;

    private type NotifyCanisterArgs = Types.NotifyCanisterArgs;

    private type Ledger = Types.Ledger;

    let CYCLE_MINTING_CANISTER = Principal.fromText("rkp4c-7iaaa-aaaaa-aaaca-cai");
    let ledger : Ledger = actor("ryjl3-tyaaa-aaaaa-aaaba-cai");
    let TOP_UP_CANISTER_MEMO = 0x50555054 : Nat64;

    private type DeployArgs = Types.DeployArgs;

    public shared({caller}) func deployCanister(
        args : DeployArgs
    ) : async Result.Result<Principal, Error>{
        if(caller != owner){
            return #err(#Invalid_Caller)
        };
        if(args.cycle_amount >= Cycles.balance()){
            return #err(#Insufficient_Cycles)
        };
        Cycles.add(args.cycle_amount);
        let management : Management = actor("aaaaa-aa");
        let _canister_id = (await management.create_canister({ settings = args.settings })).canister_id;
        canisters.put(_canister_id, {
            name = args.name;
            description = args.description;
            canister_id = _canister_id;
            wasm = if(args.preserve_wasm){
                ?args.wasm
            }else{
                null
            };
        });
        ignore await management.update_settings({
            canister_id = _canister_id;
            settings = {
                freezing_threshold = null;
                controllers = ?[Principal.fromActor(this), caller];
                memory_allocation = null;
                compute_allocation = null;
            }
        });
        ignore await management.install_code({
            arg = [];
            wasm_module = args.wasm;
            mode = #install;
            canister_id = _canister_id;
        });
        let record = {
            canister_id = _canister_id;
            method = #deploy;
            amount = args.cycle_amount;
            times = Time.now();
        };
        switch(records.get(record.canister_id)){
            case(null) {records.put(record.canister_id,[record])};
            case(?r){
                let p = Array.append(r,[record]);
                records.put(record.canister_id,p);
            }
        };
        #ok(_canister_id)
    };

    public shared({caller}) func startCanister(principal : Principal) : async Result.Result<Text, Text> {
        let management : Management = actor("aaaaa-aa");
        await management.start_canister({ canister_id = principal});
        let record = {
            canister_id = principal;
            method = #start;
            amount = 0;
            times = Time.now();
        };
        switch(records.get(record.canister_id)){
            case(null) {records.put(record.canister_id,[record])};
            case(?r){
                let p = Array.append(r,[record]);
                records.put(record.canister_id,p);
            }
        };
        #ok("start canister successfully")

    };

    public shared({caller}) func stopCanister(principal : Principal) : async Result.Result<Text, Text> {
        let management : Management = actor("aaaaa-aa");
        await management.stop_canister({ canister_id = principal});
        let record = {
            canister_id = principal;
            method = #stop;
            amount = 0;
            times = Time.now();
        };
        switch(records.get(record.canister_id)){
            case(null) {records.put(record.canister_id,[record])};
            case(?r){
                let p = Array.append(r,[record]);
                records.put(record.canister_id,p);
            }
        };
        #ok("stop canister successfully")

    };

    public shared({caller}) func depositCycles(
        id : Principal,
        cycle_amount : Nat,
    ) : async Result.Result<(), Error>{
        /// 0.01 T cycles 剩下
        if(cycle_amount + 10_000_000_000 >= Cycles.balance()){
            return #err(#Insufficient_Cycles)
        }else if(caller != owner){
            return #err(#Invalid_Caller)
        };
        let management : Management = actor("aaaaa-aa");
        Cycles.add(cycle_amount);
        ignore await management.deposit_cycles({ canister_id = id });
        let record = {
            canister_id = id;
            method = #deposit;
            amount = cycle_amount;
            times = Time.now();
        };
        switch(records.get(record.canister_id)){
            case(null) {records.put(record.canister_id,[record])};
            case(?r){
                let p = Array.append(r,[record]);
                records.put(record.canister_id,p);
            }
        };
        #ok(())
    };

    private type InterfaceError = Types.InterfaceError;

    private type CycleInterface = Types.CycleInterface;

    public shared({caller}) func delCanister(
        id : Principal,
        cycle_to : ?Principal
    ) : async Result.Result<(), Error>{
        if(caller != owner){
            return #err(#Invalid_Caller)
        };
        // install wasm
        let management : Management = actor("aaaaa-aa");
        ignore await management.install_code({
            arg = [];
            wasm_module = cycle_wasm;
            mode = #reinstall;
            canister_id = id;
        });
        // call to interface
        let from : CycleInterface = actor(Principal.toText(id));
        await from.withdraw_cycles(cycle_to);
        ignore await management.stop_canister({canister_id = id });
        ignore await management.delete_canister({ canister_id = id });
        canisters.delete(id);
        #ok(())
    };

    public func wallet_receive() : async (){
        ignore Cycles.accept(Cycles.available())
    };

    system func preupgrade(){
        canisters_entries := Iter.toArray(canisters.entries());
        record_entries := Iter.toArray(records.entries());
    };

    system func postupgrade(){
        canisters_entries := [];
        record_entries := [];
    };



};