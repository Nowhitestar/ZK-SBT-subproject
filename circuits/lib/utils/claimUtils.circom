pragma circom 2.0.0;

include "../../../node_modules/circomlib/circuits/bitify.circom";
include "../../../node_modules/circomlib/circuits/eddsaposeidon.circom";
include "../../../node_modules/circomlib/circuits/smt/smtverifier.circom";
include "../../../node_modules/circomlib/circuits/mux3.circom";
include "../../../node_modules/circomlib/circuits/mux1.circom";
include "../../../node_modules/circomlib/circuits/mux2.circom";


// getValueByIndex select slot from claim by given index
template getMultiValueByIndex(num){
  signal input claim[8];
  signal input index[num];
  signal output value[num]; // value from the selected slot claim[index]

  component mux = Mux3();
  component n2b = Num2Bits(8);
  for (var i=0; i<num; i++) { 
    n2b.in <== index[num];
    for(var i=0;i<8;i++){
        mux.c[i] <== claim[i];
        }

    mux.s[0] <== n2b.out[0];
    mux.s[1] <== n2b.out[1];
    mux.s[2] <== n2b.out[2];

    value[num] <== mux.out;
  }
}