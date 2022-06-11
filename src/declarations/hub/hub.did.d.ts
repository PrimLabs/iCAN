import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface Canister {
  'name' : string,
  'canister_id' : Principal,
  'wasm' : [] | [Array<number>],
  'description' : string,
}
export interface CanisterStatus {
  'status' : { 'stopped' : null } |
    { 'stopping' : null } |
    { 'running' : null },
  'memory_size' : bigint,
  'cycles' : bigint,
  'settings' : definite_canister_settings,
  'module_hash' : [] | [Array<number>],
}
export interface DeployArgs {
  'preserve_wasm' : boolean,
  'name' : string,
  'wasm' : [] | [Array<number>],
  'description' : string,
  'cycle_amount' : bigint,
  'settings' : [] | [canister_settings],
  'deploy_arguments' : [] | [Array<number>],
}
export type Error = { 'Create_Canister_Failed' : bigint } |
  { 'Ledger_Transfer_Failed' : bigint } |
  { 'Insufficient_Cycles' : null } |
  { 'No_Record' : null } |
  { 'Invalid_CanisterId' : null } |
  { 'Invalid_Caller' : null } |
  { 'No_Wasm' : null };
export interface InstallArgs {
  'arg' : Array<number>,
  'wasm_module' : Array<number>,
  'mode' : { 'reinstall' : null } |
    { 'upgrade' : null } |
    { 'install' : null },
  'canister_id' : Principal,
}
export type Result = { 'ok' : null } |
  { 'err' : Error };
export type Result_1 = { 'ok' : Array<number> } |
  { 'err' : Error };
export type Result_2 = { 'ok' : Status } |
  { 'err' : Error };
export type Result_3 = { 'ok' : Array<Canister> } |
  { 'err' : Error };
export type Result_4 = { 'ok' : Principal } |
  { 'err' : Error };
export type Result_5 = { 'ok' : CanisterStatus } |
  { 'err' : Error };
export interface Status { 'memory' : bigint, 'cycle_balance' : bigint }
export interface UpdateSettingsArgs {
  'canister_id' : Principal,
  'settings' : canister_settings,
}
export interface canister_settings {
  'freezing_threshold' : [] | [bigint],
  'controllers' : [] | [Array<Principal>],
  'memory_allocation' : [] | [bigint],
  'compute_allocation' : [] | [bigint],
}
export interface definite_canister_settings {
  'freezing_threshold' : bigint,
  'controllers' : Array<Principal>,
  'memory_allocation' : bigint,
  'compute_allocation' : bigint,
}
export interface hub {
  'addOwner' : ActorMethod<[Principal], Result>,
  'canisterStatus' : ActorMethod<[Principal], Result_5>,
  'changeOwner' : ActorMethod<[Array<Principal>], Result>,
  'clearLog' : ActorMethod<[], undefined>,
  'delCanister' : ActorMethod<[Principal], Result>,
  'deleteOwner' : ActorMethod<[Principal], Result>,
  'deployCanister' : ActorMethod<[DeployArgs], Result_4>,
  'depositCycles' : ActorMethod<[Principal, bigint], Result>,
  'getCanisters' : ActorMethod<[], Result_3>,
  'getLog' : ActorMethod<[], Array<[bigint, string]>>,
  'getOwners' : ActorMethod<[], Array<Principal>>,
  'getStatus' : ActorMethod<[], Result_2>,
  'getVersion' : ActorMethod<[], bigint>,
  'getWasm' : ActorMethod<[Principal], Result_1>,
  'init' : ActorMethod<[Principal, Array<number>], undefined>,
  'installCycleWasm' : ActorMethod<[Array<number>], Result>,
  'installWasm' : ActorMethod<[InstallArgs], Result>,
  'isOwner' : ActorMethod<[], boolean>,
  'putCanister' : ActorMethod<[Canister], Result>,
  'startCanister' : ActorMethod<[Principal], Result>,
  'stopCanister' : ActorMethod<[Principal], Result>,
  'updateCanisterSettings' : ActorMethod<[UpdateSettingsArgs], Result>,
  'wallet_receive' : ActorMethod<[], undefined>,
}
export interface _SERVICE extends hub {}
