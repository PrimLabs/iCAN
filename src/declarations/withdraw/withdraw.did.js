export const idlFactory = ({ IDL }) => {
  const CycleActor = IDL.Service({ 'withdraw_cycles' : IDL.Func([], [], []) });
  return CycleActor;
};
export const init = ({ IDL }) => { return []; };
