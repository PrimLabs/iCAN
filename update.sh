git pull
rm -rf ./update/hub.wasm
rm -rf ./update/cycle.wasm
rm -rf .dfx
dfx build --network ic
cp .dfx/ic/canisters/hub/hub.wasm ./update
cp .dfx/ic/canisters/cycle/cycle.wasm ./update
cd update || exit
cargo run "$1"
rm -rf src/lastest_wasm/cycle.wasm
rm -rf src/lastest_wasm/hub.wasm
cp ./update/hub.wasm src/lastest_wasm/
cp ./update/cycle.wasm src/lastest_wasm/
git add src/lastest_wasm/
git commit -m "update lastest wasm"
git push