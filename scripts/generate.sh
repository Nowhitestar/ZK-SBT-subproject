#!/bin/sh

set -e

generate_proof() {
  CIRCUIT="$(pwd)/build/$1"
  CIRCUIT_JS="$(pwd)/build/$1/$1_js"
  
  # compile circuit

  echo "Compiling circuit.circom..."
  circom $CIRCUIT/circuit.circom --r1cs --wasm --sym -o circuit
  snarkjs r1cs info $CIRCUIT/circuit.r1cs

  # Start a new zkey and make a contribution

  snarkjs groth16 setup $CIRCUIT/circuit.r1cs powersOfTau28_hez_final_15.ptau $CIRCUIT/circuit_0000.zkey
  snarkjs zkey contribute $CIRCUIT/circuit_0000.zkey $CIRCUIT/circuit_final.zkey --name="1st Contributor Name" -v -e="random text"
  snarkjs zkey export verificationkey $CIRCUIT/circuit_final.zkey $CIRCUIT/verification_key.json

  # generate solidity contract

  snarkjs zkey export solidityverifier $CIRCUIT/circuit_final.zkey $CIRCUIT/verifier.sol

  # generate witness

  node $CIRCUIT_JS/generate_witness.js $CIRCUIT/circuit.wasm $CIRCUIT_JS/input.json $CIRCUIT_JS/witness.wtns

  snarkjs groth16 prove $CIRCUIT/circuit_final.zkey $CIRCUIT_JS/witness.wtns $CIRCUIT_JS/proof.json $CIRCUIT_JS/public.json

  snarkjs groth16 verify $CIRCUIT/verification_key.json $CIRCUIT_JS/public.json $CIRCUIT_JS/proof.json

  snarkjs zkey export soliditycalldata $CIRCUIT_JS/public.json $CIRCUIT_JS/proof.json > build/verify/verify_js/call.txt
}

generate_proof $1