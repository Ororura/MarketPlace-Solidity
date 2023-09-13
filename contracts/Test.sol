// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
    function randMod(uint _modulus) public view returns(uint)
    {   
        uint randNonce;
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % _modulus;
    }
}