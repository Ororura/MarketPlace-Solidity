// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract MarketPlace2{

    address public owner = msg.sender;
    uint public breadPrice;
    uint public breadInStock;
    

    enum Role {buyer, market }

    struct User {
        address id;
        uint role;
        uint balance;

    }

    constructor(uint _breadPrice, uint _breadInStock){
        breadPrice = _breadPrice * 1 ether;
        breadInStock = _breadInStock;

    }

    User public market = User(owner, uint(Role.market), 0);

    function purchaseBread(uint _amount) public payable {
            User storage buyer = User(msg.sender, uint(Role.buyer), msg.value); 
            require(_amount <= breadInStock);
            require(_amount >0);
            uint totalPrice = _amount * breadPrice;

    }

    
    
}