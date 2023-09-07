// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract MarketPlace {
    address public owner;

    enum Role { User, Market }

    struct User {
        uint purchased;
        Role role;
        Product[] product;
    }

    struct Product {
        uint inStock;
        uint price;
        string name;
    }

    mapping(address => User) public users;

    constructor(uint _breadPrice, uint _breadInStock) {
        owner = msg.sender;
        users[owner] = User(0, Role.Market);
    }

    function addItems(uint _inStock, uint _price, string _name) public {
        Product item = Product(_inStock, _price, _name);
        users[owner].product.push(item);
    }

    function purchaseBread(uint _amount) public payable {
        require(_amount <= users[owner][0]);
        require(_amount > 0);
        uint totalPrice = _amount * markets[owner].breadPrice;
        require(msg.value >= totalPrice);

        markets[owner].breadInStock -= _amount;
        users[msg.sender].breadsPurchased += _amount;

        if (msg.value > totalPrice) {
            uint change = msg.value - totalPrice;
            payable(msg.sender).transfer(change);
        }

        uint balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    function showBreadsPurchased() public view returns (uint) {
        return users[msg.sender].breadsPurchased;
    }

    function showBreadsInStock() public view returns(uint) {
        return markets[owner].breadInStock;
    }


}
