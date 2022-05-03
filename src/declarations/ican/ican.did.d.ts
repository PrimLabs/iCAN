import type { Principal } from '@dfinity/principal';
export type Error = { 'Create_Canister_Failed' : bigint } |
  { 'Ledger_Transfer_Failed' : bigint } |
  { 'Insufficient_Cycles' : null } |
  { 'No_Record' : null } |
  { 'Invalid_CanisterId' : null } |
  { 'Invalid_Caller' : null } |
  { 'No_Wasm' : null };
export type Result = { 'ok' : null } |
  { 'err' : Error };
export type Result_1 = { 'ok' : Principal } |
  { 'err' : Error };
export interface TransformArgs {
  'to_canister_id' : Principal,
  'icp_amount' : bigint,
}
export interface _SERVICE {
  'changeAdministrator' : (arg_0: Array<Principal>) => Promise<string>,
  'createHub' : (arg_0: bigint) => Promise<Result_1>,
  'getBucket' : () => Promise<Array<Principal>>,
  'topUpSelf' : (arg_0: Principal) => Promise<undefined>,
  'transformIcp' : (arg_0: TransformArgs) => Promise<Result>,
  'uploadCycleWasm' : (arg_0: Array<number>) => Promise<string>,
  'uploadHubWasm' : (arg_0: Array<number>) => Promise<string>,
  'wallet_receive' : () => Promise<undefined>,
}
