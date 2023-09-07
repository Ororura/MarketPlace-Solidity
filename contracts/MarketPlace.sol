// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract MarketPlace{
    address public owner;
    uint public breadPrice;
    uint public breadInStock;
    mapping (address => uint) customerBreads;

    constructor(uint _breadPrice, uint _breadInStock){
        owner = msg.sender;
        breadPrice = _breadPrice * 1 ether;
        breadInStock = _breadInStock;
    }

    function setBreadPrice (uint _breadPrice) public {
        breadPrice = _breadPrice * 1 ether;
    }

    function purchaseBread(uint _amount) public payable {
        require(_amount <= breadInStock);
        require(_amount >0);
        uint totalPrice = _amount * breadPrice;
        require(msg.value >= totalPrice);
        breadInStock --;
        customerBreads[msg.sender]+= _amount;

        if(msg.value > totalPrice){
           uint change = msg.value - totalPrice;
           payable (msg.sender).transfer(change);
        }

        uint balance = address(this).balance;
        payable(owner).transfer(balance);

    }

    function showBreads() public view returns(uint){
        return customerBreads[msg.sender];
    }

    
}