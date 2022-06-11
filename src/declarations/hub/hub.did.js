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
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : Error });
  const definite_canister_settings = IDL.Record({
    'freezing_threshold' : IDL.Nat,
    'controllers' : IDL.Vec(IDL.Principal),
    'memory_allocation' : IDL.Nat,
    'compute_allocation' : IDL.Nat,
  });
  const CanisterStatus = IDL.Record({
    'status' : IDL.Variant({
      'stopped' : IDL.Null,
      'stopping' : IDL.Null,
      'running' : IDL.Null,
    }),
    'memory_size' : IDL.Nat,
    'cycles' : IDL.Nat,
    'settings' : definite_canister_settings,
    'module_hash' : IDL.Opt(IDL.Vec(IDL.Nat8)),
  });
  const Result_5 = IDL.Variant({ 'ok' : CanisterStatus, 'err' : Error });
  const canister_settings = IDL.Record({
    'freezing_threshold' : IDL.Opt(IDL.Nat),
    'controllers' : IDL.Opt(IDL.Vec(IDL.Principal)),
    'memory_allocation' : IDL.Opt(IDL.Nat),
    'compute_allocation' : IDL.Opt(IDL.Nat),
  });
  const DeployArgs = IDL.Record({
    'preserve_wasm' : IDL.Bool,
    'name' : IDL.Text,
    'wasm' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'description' : IDL.Text,
    'cycle_amount' : IDL.Nat,
    'settings' : IDL.Opt(canister_settings),
    'deploy_arguments' : IDL.Opt(IDL.Vec(IDL.Nat8)),
  });
  const Result_4 = IDL.Variant({ 'ok' : IDL.Principal, 'err' : Error });
  const Canister = IDL.Record({
    'name' : IDL.Text,
    'canister_id' : IDL.Principal,
    'wasm' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'description' : IDL.Text,
  });
  const Result_3 = IDL.Variant({ 'ok' : IDL.Vec(Canister), 'err' : Error });
  const Status = IDL.Record({ 'memory' : IDL.Nat, 'cycle_balance' : IDL.Nat });
  const Result_2 = IDL.Variant({ 'ok' : Status, 'err' : Error });
  const Result_1 = IDL.Variant({ 'ok' : IDL.Vec(IDL.Nat8), 'err' : Error });
  const InstallArgs = IDL.Record({
    'arg' : IDL.Vec(IDL.Nat8),
    'wasm_module' : IDL.Vec(IDL.Nat8),
    'mode' : IDL.Variant({
      'reinstall' : IDL.Null,
      'upgrade' : IDL.Null,
      'install' : IDL.Null,
    }),
    'canister_id' : IDL.Principal,
  });
  const UpdateSettingsArgs = IDL.Record({
    'canister_id' : IDL.Principal,
    'settings' : canister_settings,
  });
  const hub = IDL.Service({
    'addOwner' : IDL.Func([IDL.Principal], [Result], []),
    'canisterStatus' : IDL.Func([IDL.Principal], [Result_5], []),
    'changeOwner' : IDL.Func([IDL.Vec(IDL.Principal)], [Result], []),
    'clearLog' : IDL.Func([], [], []),
    'delCanister' : IDL.Func([IDL.Principal], [Result], []),
    'deleteOwner' : IDL.Func([IDL.Principal], [Result], []),
    'deployCanister' : IDL.Func([DeployArgs], [Result_4], []),
    'depositCycles' : IDL.Func([IDL.Principal, IDL.Nat], [Result], []),
    'getCanisters' : IDL.Func([], [Result_3], ['query']),
    'getLog' : IDL.Func([], [IDL.Vec(IDL.Tuple(IDL.Nat, IDL.Text))], ['query']),
    'getOwners' : IDL.Func([], [IDL.Vec(IDL.Principal)], ['query']),
    'getStatus' : IDL.Func([], [Result_2], ['query']),
    'getVersion' : IDL.Func([], [IDL.Nat], ['query']),
    'getWasm' : IDL.Func([IDL.Principal], [Result_1], ['query']),
    'init' : IDL.Func([IDL.Principal, IDL.Vec(IDL.Nat8)], [], []),
    'installCycleWasm' : IDL.Func([IDL.Vec(IDL.Nat8)], [Result], []),
    'installWasm' : IDL.Func([InstallArgs], [Result], []),
    'isOwner' : IDL.Func([], [IDL.Bool], ['query']),
    'putCanister' : IDL.Func([Canister], [Result], []),
    'startCanister' : IDL.Func([IDL.Principal], [Result], []),
    'stopCanister' : IDL.Func([IDL.Principal], [Result], []),
    'updateCanisterSettings' : IDL.Func([UpdateSettingsArgs], [Result], []),
    'wallet_receive' : IDL.Func([], [], []),
  });
  return hub;
};
export const init = ({ IDL }) => { return []; };
