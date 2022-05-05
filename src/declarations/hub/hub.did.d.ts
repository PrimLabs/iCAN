import type { Principal } from '@dfinity/principal';
export interface Canister {
  'name' : string,
  'canister_id' : Principal,
  'wasm' : [] | [Array<number>],
  'description' : string,
}
export interface DeployArgs {
  'preserve_wasm' : boolean,
  'name' : string,
  'wasm' : Array<number>,
  'description' : string,
  'cycle_amount' : bigint,
  'settings' : [] | [canister_settings],
}
export type Error = { 'Create_Canister_Failed' : bigint } |
  { 'Ledger_Transfer_Failed' : bigint } |
  { 'Insufficient_Cycles' : null } |
  { 'No_Record' : null } |
  { 'Invalid_CanisterId' : null } |
  { 'Invalid_Caller' : null } |
  { 'No_Wasm' : null };
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
export interface Status { 'memory' : bigint, 'cycle_balance' : bigint }
export interface canister_settings {
  'freezing_threshold' : [] | [bigint],
  'controllers' : [] | [Array<Principal>],
  'memory_allocation' : [] | [bigint],
  'compute_allocation' : [] | [bigint],
}
export interface hub {
  'changeOwner' : (arg_0: Array<Principal>) => Promise<Result>,
  'delCanister' : (arg_0: Principal) => Promise<Result>,
  'deployCanister' : (arg_0: DeployArgs) => Promise<Result_4>,
  'depositCycles' : (arg_0: Principal, arg_1: bigint) => Promise<Result>,
  'getCanisters' : () => Promise<Result_3>,
  'getOwners' : () => Promise<Array<Principal>>,
  'getStatus' : () => Promise<Result_2>,
  'getWasm' : (arg_0: Principal) => Promise<Result_1>,
  'installCycleWasm' : (arg_0: Array<number>) => Promise<Result>,
  'putCanister' : (arg_0: Canister) => Promise<Result>,
  'startCanister' : (arg_0: Principal) => Promise<Result>,
  'stopCanister' : (arg_0: Principal) => Promise<Result>,
  'wallet_receive' : () => Promise<undefined>,
}
export interface _SERVICE extends hub {}
