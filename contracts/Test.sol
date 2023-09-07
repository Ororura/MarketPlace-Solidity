// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
    address public owner;
    enum Role { User, Market }

    struct User {
        uint purchased;
        Role role;
    }

    struct Product {
        uint inStock;
        uint price;
        string name;
    }

    mapping(address => User) public users;
    mapping(address => Product[]) public userProducts;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
        users[owner] = User(0, Role.Market);
    }

    function addItems(uint _inStock, uint _price, string calldata _name) public onlyOwner {
        Product memory item = Product(_inStock, _price, _name);
        userProducts[owner].push(item);
    }

    function showItems() public view returns (Product[] memory) {
        return userProducts[owner];
    }

    function showInStock(uint productId) public view returns (uint) {
        require(productId < userProducts[owner].length, "Invalid product ID");
        return userProducts[owner][productId].inStock;
    }

    function purchase(uint _amount, uint _id) public payable {
            require(_amount <= userProducts[owner][_id].inStock); // Покупают меньше, чем в наличии
            require(_amount >0); // Покупают больше, чем 0
            uint totalPrice = _amount * userProducts[owner][_id].price;
            require(msg.value >= totalPrice);

            Product memory item = Product(_amount, userProducts[owner][0].price, userProducts[owner][0].name);
            userProducts[owner][_id].inStock -= _amount;
            userProducts[msg.sender].push(item);

            if (msg.value > totalPrice) {
                uint change = msg.value - totalPrice;
                payable(msg.sender).transfer(change);
            }

            uint balance = address(this).balance;
            payable(owner).transfer(balance);

    }

    // Исправить появление второго пользователя при покупке 
}
