import type { Principal } from '@dfinity/principal';
export interface CycleActor { 'withdraw_cycles' : () => Promise<undefined> }
export interface _SERVICE extends CycleActor {}
