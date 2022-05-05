import Array "mo:base/Array";
import Account "Lib/Account";
import Blob  "mo:base/Blob";
import Bucket "Lib/Bucket";
import Cycles "mo:base/ExperimentalCycles";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";
import TrieSet "mo:base/TrieSet";
import Types "Lib/Types";

actor iCAN{

    type Management = Types.Management;
    type Memo = Types.Memo;
    type AccountIdentifier = Types.AccountIdentifier;
    type SubAccount = Types.SubAccount;
    type Ledger = Types.Ledger;
    type CMC = Types.CMC;
    type TransformArgs = Types.TransformArgs;
    type HubInterface = Types.HubInterface;
    type Error = Types.Error;
    type wasm_module = Types.wasm_module;

    let CYCLE_MINTING_CANISTER = Principal.fromText("rkp4c-7iaaa-aaaaa-aaaca-cai");
    let cmc : CMC = actor("rkp4c-7iaaa-aaaaa-aaaca-cai");
    let ledger : Ledger = actor("ryjl3-tyaaa-aaaaa-aaaba-cai");
    let management : Management = actor("aaaaa-aa");
    let TOP_UP_CANISTER_MEMO = 0x50555054 : Nat64;
    let CREATE_CANISTER_MEMO = 0x41455243 : Nat64;
    let CYCLE_THRESHOLD = 4_000_000_000_000;

    stable var administrators : TrieSet.Set<Principal> = TrieSet.empty<Principal>(Principal.hash, Principal.equal);
    stable var cycle_wasm : [Nat8] = [];
    stable var hub_wasm : [Nat8] = [];
    stable var bucket_upgrade_params : (Nat, [(Nat,(Nat64, Nat))]) = (0, []);
    stable var log_index = 0;
    stable var entries : [(Principal, [Principal])] = [];

    var logs = Bucket.Bucket(true);
    var hubs : TrieMap.TrieMap<Principal, [Principal]> = TrieMap.fromEntries<Principal, [Principal]>(entries.vals(), Principal.equal, Principal.hash);

    public shared({caller}) func changeAdministrator(nas : [Principal]): async Text{
        assert(TrieSet.mem<Principal>(administrators, caller, Principal.hash(caller), Principal.equal));
        administrators := TrieSet.fromArray<Principal>(nas, Principal.hash, Principal.equal);
        "successfully"
    };

    public shared({caller}) func uploadCycleWasm(_wasm : [Nat8]) : async Text{
        assert(TrieSet.mem<Principal>(administrators, caller, Principal.hash(caller), Principal.equal));
        cycle_wasm := _wasm;
        "successfully"
    };

    public shared({caller}) func uploadHubWasm(_wasm : [Nat8]) : async Text{
        assert(TrieSet.mem<Principal>(administrators, caller, Principal.hash(caller), Principal.equal));
        hub_wasm := _wasm;
        "successfully"
    };

    public shared({caller}) func createHub(amount : Nat64) : async Result.Result<Principal, Error>{
        assert(amount > 1_020_000);
        let subaccount = Blob.fromArray(Account.principalToSubAccount(caller));
        let ican_cycle_subaccount = Blob.fromArray(Account.principalToSubAccount(Principal.fromActor(iCAN)));
        let ican_cycle_ai = Account.accountIdentifier(CYCLE_MINTING_CANISTER, ican_cycle_subaccount);
        ignore await topUpSelf(caller);
        ignore _addLog("Transfer Service Fee Successfully, caller : "#debug_show(caller)#" , Time : "#debug_show(Time.now()));
        switch(await ledger.transfer({
            to = ican_cycle_ai;
            fee = { e8s = 10_000 }; // 0.0001
            memo = CREATE_CANISTER_MEMO;
            from_subaccount = ?subaccount;
            amount = { e8s = amount - 1_020_000 };
            created_at_time = null;
        })){
            case(#Ok(block_height)){
                ignore _addLog("Transfer Top Up Fee Successfully, Caller : "#debug_show(caller)#" , Time : "#debug_show(Time.now()));
                switch(await cmc.notify_create_canister({
                   block_index = block_height;
                   controller = Principal.fromActor(iCAN);
                })){
                    case(#Ok(id)){
                        let h : HubInterface = actor(Principal.toText(id));
                        _addHub(caller, id);
                        ignore await management.install_code({
                            arg = [];
                            wasm_module = hub_wasm;
                            mode = #install;
                            canister_id = id;
                        });
                        ignore await h.installCycleWasm(cycle_wasm);
                        ignore await h.changeOwner([caller]);
                        ignore await management.update_settings({
                            canister_id = id;
                            settings = {
                                freezing_threshold = null;
                                controllers = ?[caller];
                                memory_allocation = null;
                                compute_allocation = null;
                            }
                        });
                        ignore _addLog("Create Canister Successfully, caller : " # debug_show(caller) # "Time : "#debug_show(Time.now()) # "canister id : " # debug_show(id));
                        #ok(id)
                    };
                    case(#Err(e)){
                        #err(#Create_Canister_Failed(_addLog("Notify Create Canister Failed, caller : "#debug_show(caller)#" , Time : "#debug_show(Time.now())#", Error : "#debug_show(e)#" Args : " # debug_show(amount))));
                    }
                }
            };
            case(#Err(e)){
                #err(#Create_Canister_Failed(_addLog("Transfer Create Canister Fee Failed, caller : "#debug_show(caller)#" , Time : "#debug_show(Time.now())#", Error : "#debug_show(e)#" Args : " # debug_show(amount))))
            }
        }
    };

    public shared({caller}) func addHub(
        hub_id : Principal
    ) : async Text{
        switch(hubs.get(caller)){
            case null {
                hubs.put(caller, [hub_id])
            };
            case(?ps){
                hubs.put(caller, Array.append(ps, [hub_id]))
            }
        };
        "success"
    };

    public shared({caller}) func deleteHub(
        hub_id : Principal
    ) : async Result.Result<(), Error>{
        switch(hubs.get(caller)){
            case null {
                #err(#Invalid_Caller)
            };
            case(?ps){
                let res = Array.init<Principal>(ps.size() - 1, Principal.fromActor(iCAN));
                var _index = 0;
                for(p in ps.vals()){
                    if(p != hub_id){
                        res[_index] := p;
                        _index += 1;
                    };
                };
                hubs.put(caller, Array.freeze<Principal>(res));
                #ok(())
            }
        }
    };

    public shared({caller}) func transformIcp(
        args : TransformArgs
    ) : async Result.Result<(), Error>{
        assert(args.icp_amount > 1_010_000);
        ignore await topUpSelf(caller);
        let subaccount = Blob.fromArray(Account.principalToSubAccount(caller));
        let cycle_subaccount = Blob.fromArray(Account.principalToSubAccount(args.to_canister_id));
        let cycle_ai = Account.accountIdentifier(CYCLE_MINTING_CANISTER, cycle_subaccount);
        switch(await ledger.transfer({
            to = cycle_ai;
            fee = { e8s = 10_000 };
            memo = TOP_UP_CANISTER_MEMO;
            from_subaccount = ?subaccount;
            amount = { e8s = args.icp_amount - 1_010_000 };
            created_at_time = null;
        })){
            case(#Err(e)){
                #err(#Ledger_Transfer_Failed(_addLog("Transfer Service Fee Failed, caller : "#debug_show(caller)#" , Time : "#debug_show(Time.now())#" Error : " # debug_show(e) #" Args : " # debug_show(args))))
            };
            case(#Ok(height)){
                ignore await cmc.notify_top_up(
                    {
                        block_index = height;
                        canister_id = args.to_canister_id;
                    }
                );
                #ok(())
            }
        }
    };

    public shared({caller}) func topUpSelf(_caller : Principal) : async (){
        assert(caller == Principal.fromActor(iCAN));
        let subaccount = Blob.fromArray(Account.principalToSubAccount(_caller));
        let cycle_subaccount = Blob.fromArray(Account.principalToSubAccount(Principal.fromActor(iCAN)));
        let cycle_ai = Account.accountIdentifier(CYCLE_MINTING_CANISTER, cycle_subaccount);
        switch(await ledger.transfer({
            to = cycle_ai;
            fee = { e8s = 10_000 };
            memo = TOP_UP_CANISTER_MEMO;
            from_subaccount = ?subaccount;
            amount = { e8s = 990_000 };
            created_at_time = null;
        })){
            case(#Err(e)){
                ignore _addLog("Top Up Self Failed, caller : "#debug_show(_caller)#" , Time : "#debug_show(Time.now())#" Error : " # debug_show(e))
            };
            case(#Ok(height)){
                ignore await cmc.notify_top_up(
                    {
                      block_index = height;
                      canister_id = Principal.fromActor(iCAN);
                    }
                );
                ignore _addLog("Top Up Self Successfully, caller : "#debug_show(_caller)#" , Time : "#debug_show(Time.now()))
            }
        }
    };

    public query({caller}) func getBucket() : async [Principal]{
        switch(hubs.get(caller)){
            case null { [] };
            case(?b){ b }
        }
    };

    public query({caller}) func getLog() : async [(Nat, ?Text)]{
        let res = Array.init<(Nat, ?Text)>(log_index, (0, null));
        var index = 0;
        for(l in res.vals()){
            res[index] := logs.get(index);
            index += 1;
        };
        Array.freeze<(Nat, ?Text)>(res)
    };

    private func _addHub(owner : Principal, canister_id : Principal){
        switch(hubs.get(owner)){
            case(null) { hubs.put(owner,[canister_id]) };
            case(?b){
                let p = Array.append(b, [canister_id]);
                hubs.put(owner, p);
            }
        };
    };

    // return log id
    private func _addLog(log : Text) : Nat{
        let id = log_index;
        ignore logs.put(id, log);
        log_index += 1;
        id
    };

    system func preupgrade(){
        entries := Iter.toArray(hubs.entries());
        bucket_upgrade_params := logs.preupgrade();
    };

    system func postupgrade(){
        entries := [];
        logs.postupgrade(bucket_upgrade_params);
        bucket_upgrade_params := (0, []);
    };

    public func wallet_receive() : async (){
        ignore Cycles.accept(Cycles.available())
    };

};
