import TrieMap "mo:base/TrieMap";
import Result "mo:base/Result";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat64 "mo:base/Nat64";
import SM "mo:base/ExperimentalStableMemory";
import Prim "mo:⛔";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";

module {

    public type Error = {
        #INSUFFICIENT_MEMORY;
        #BlobSizeError;
        #INVALID_KEY;
        #Append_Error;
    };

    public class Bucket(upgradable : Bool) {
        private let THRESHOLD               = 6442450944;
        // MAX_PAGE_SIZE = 8 GB(total size of stable memory currently) / 64 KB(each page size = 64 KB)
        private let MAX_PAGE_BYTE               = 65536;
        private let MAX_PAGE_NUMBER         = 131072 : Nat64;
        private let MAX_QUERY_SIZE          = 3144728;
        private var offset                  = 0;
        var assets = TrieMap.TrieMap<Nat, (Nat64, Nat)>(Nat.equal, Hash.hash);

        public func put(key: Nat, value : Text): Result.Result<(), Error> {
            let data = Text.encodeUtf8(value);
            switch(_getField(data.size())) {
                case(#ok(field)) {
                    assets.put(key, field);
                    _storageData(field.0, data);
                };
                case(#err(err)) { return #err(err) };
            };
            #ok(())
        };

        public func get(key: Nat): (Nat, Text) {
            (
                key,
                switch(do?{ Text.decodeUtf8(_loadFromSM(assets.get(key)!))! }){
                    case null { "decode log failed "};
                    case(?t){ t }
                }
            )
        };

        public func clear(){
            offset := 0;
            assets := TrieMap.TrieMap<Nat, (Nat64, Nat)>(Nat.equal, Hash.hash);
        };

        // return entries
        public func preupgrade(): (Nat, [(Nat, (Nat64, Nat))]) {
            var index = 0;
            var assets_entries = Array.init<(Nat, (Nat64, Nat))>(assets.size(), (0, (0,0)));
            for (kv in assets.entries()) {
                assets_entries[index] := kv;
                index += 1;
            };
            (offset, Array.freeze<(Nat, (Nat64, Nat))>(assets_entries))
        };

        public func postupgrade(params : (Nat, [(Nat, (Nat64, Nat))])): () {
            offset := params.0;
            assets := TrieMap.fromEntries<Nat, (Nat64, Nat)>(params.1.vals(), Nat.equal, Hash.hash);
        };

        private func _loadFromSM(field : (Nat64, Nat)) : Blob {
            SM.loadBlob(field.0, field.1)
        };

        private func _getField(total_size : Nat) : Result.Result<(Nat64, Nat), Error> {
            switch (_inspectSize(total_size)) {
                case (#err(err)) { #err(err) };
                case (#ok(_)) {
                    let field = (Nat64.fromNat(offset), total_size);
                    _growStableMemoryPage(total_size);
                    offset += total_size;
                    #ok(field)
                };
            }
        };

        // check total_size
        private func _inspectSize(total_size : Nat) : Result.Result<(), Error> {
            if (total_size <= _getAvailableMemorySize()) { #ok(()) } else { #err(#INSUFFICIENT_MEMORY) };
        };

        // When uploading, write data in the form of vals according to the assigned write_page
        private func _storageData(start : Nat64, data : Blob) {
            SM.storeBlob(start, data)
        };

        // return available memory size can be allocated
        private func _getAvailableMemorySize() : Nat{
            if(upgradable){
                assert(THRESHOLD >= Prim.rts_memory_size() + offset);
                THRESHOLD - Prim.rts_memory_size() - offset
            }else{
                THRESHOLD - offset
            }
        };

        // grow SM memory pages of size "size"
        private func _growStableMemoryPage(size : Nat) {
            if(offset == 8){ ignore SM.grow(1 : Nat64) };
            let available_mem : Nat = Nat64.toNat(SM.size()) * MAX_PAGE_BYTE + 1 - offset;
            if (available_mem < size) {
                let need_allo_size : Nat = size - available_mem;
                let growPage = Nat64.fromNat(need_allo_size / MAX_PAGE_BYTE + 1);
                ignore SM.grow(growPage);
            }
        };

    };
};