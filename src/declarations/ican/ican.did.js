export const idlFactory = ({ IDL }) => {
  const Error = IDL.Variant({
    'Create_Canister_Failed' : IDL.Nat,
    'Ledger_Transfer_Failed' : IDL.Nat,
    'Insufficient_Cycles' : IDL.Null,
    'No_Record' : IDL.Null,
    'Invalid_CanisterId' : IDL.Null,
    'Invalid_Caller' : IDL.Null,
    'No_Wasm' : IDL.Null,
  });
  const Result_1 = IDL.Variant({ 'ok' : IDL.Principal, 'err' : Error });
  const TransformArgs = IDL.Record({
    'to_canister_id' : IDL.Principal,
    'icp_amount' : IDL.Nat64,
  });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : Error });
  return IDL.Service({
    'changeAdministrator' : IDL.Func([IDL.Vec(IDL.Principal)], [IDL.Text], []),
    'createHub' : IDL.Func([IDL.Nat64], [Result_1], []),
    'getBucket' : IDL.Func([], [IDL.Vec(IDL.Principal)], ['query']),
    'topUpSelf' : IDL.Func([IDL.Principal], [], []),
    'transformIcp' : IDL.Func([TransformArgs], [Result], []),
    'uploadCycleWasm' : IDL.Func([IDL.Vec(IDL.Nat8)], [IDL.Text], []),
    'uploadHubWasm' : IDL.Func([IDL.Vec(IDL.Nat8)], [IDL.Text], []),
    'wallet_receive' : IDL.Func([], [], []),
  });
};
export const init = ({ IDL }) => { return []; };
