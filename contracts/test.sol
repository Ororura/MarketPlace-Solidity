// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract BalanceExample {
    // Функция, которая возвращает баланс отправителя
    function getSenderBalance(string memory first, string memory second) public view returns (uint) {
        if (abi.encode(first) == abi.encode(second)){ // bytes -> abi.encode
                return 1;
            }
            else{ return 2;}
    }
}
