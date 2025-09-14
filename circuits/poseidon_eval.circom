pragma circom 2.1.4;
include "circomlib/circuits/poseidon.circom";

template Main() {
    signal input x;
    signal output y;
    component H = Poseidon(1);
    H.inputs[0] <== x;
    y <== H.out;
}

component main = Main();

