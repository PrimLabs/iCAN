use anyhow::bail;
use candid::{Decode, Encode, Principal};
use ic_agent::agent::http_transport::ReqwestHttpReplicaV2Transport;
use ic_agent::identity::BasicIdentity;
use ic_agent::Agent;
use serde::Deserialize;
use std::env;
use std::env::args;
use std::fs;
use tokio::*;

struct Args {
    identity: BasicIdentity,
    canister_id: Principal,
    wasm: Vec<u8>,
}

#[tokio::main]
async fn main() {
    let args: Vec<String> = env::args().collect();
    let identity = BasicIdentity::from_pem_file("identity.pem").unwrap();
    let canister_id = Principal::from_text("5hssk-kiaaa-aaaag-aaeva-cai").unwrap();
    if args.get(1).unwrap().to_string() == "hub".to_string() {
        let wasm = fs::read("hub.wasm").unwrap();
        update_hub_canister(Args {
            identity,
            canister_id,
            wasm,
        })
        .await
    } else if args.get(1).unwrap().to_string() == "cycle".to_string() {
        let wasm = fs::read("cycle.wasm").unwrap();
        update_cycle_canister(Args {
            identity,
            canister_id,
            wasm,
        })
        .await
    } else {
        eprintln!(" don't specify which wasm should be update ")
    }
}

async fn update_hub_canister(args: Args) {
    let url = "https://ic0.app";
    let transport = ReqwestHttpReplicaV2Transport::create(url).unwrap();
    let waiter = garcon::Delay::builder()
        .throttle(std::time::Duration::from_millis(10))
        .timeout(std::time::Duration::from_millis(10 * 100 * 10)) // 10 blocks
        .build();
    let agent = Agent::builder()
        .with_identity(args.identity)
        .with_transport(transport)
        .build()
        .unwrap();
    let res = agent
        .update(&args.canister_id, "uploadHubWasm")
        .with_arg(Encode!(&args.wasm).unwrap())
        .call_and_wait(waiter)
        .await;
    match res {
        Ok(msg) => {
            println!(
                "update hub canister response : {}",
                Decode!(&msg, String).unwrap()
            )
        }
        Err(e) => {
            eprintln!("Call to iCAN canister failed, Error info : \n{:?}", e)
        }
    }
}

async fn update_cycle_canister(args: Args) {
    let url = "https://ic0.app";
    let transport = ReqwestHttpReplicaV2Transport::create(url).unwrap();
    let waiter = garcon::Delay::builder()
        .throttle(std::time::Duration::from_millis(10))
        .timeout(std::time::Duration::from_millis(10 * 100 * 10)) // 10 blocks
        .build();
    let agent = Agent::builder()
        .with_identity(args.identity)
        .with_transport(transport)
        .build()
        .unwrap();
    let res = agent
        .update(&args.canister_id, "uploadCycleWasm")
        .with_arg(Encode!(&args.wasm).unwrap())
        .call_and_wait(waiter)
        .await;
    match res {
        Ok(msg) => {
            println!(
                "update hub canister response : {}",
                Decode!(&msg, String).unwrap()
            )
        }
        Err(e) => {
            eprintln!("Call to iCAN canister failed, Error info : {:?}", e)
        }
    }
}
