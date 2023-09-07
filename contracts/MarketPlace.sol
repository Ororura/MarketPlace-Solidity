// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MarketPlace {
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
        require(_amount > 0, "Purchase amount must be greater than 0");
        require(_id < userProducts[owner].length, "Invalid product ID");

        if (users[msg.sender].role != Role.User) {
        users[msg.sender] = User(0, Role.User);
    }

        require(_amount <= userProducts[owner][_id].inStock, "Not enough stock available");

        uint totalPrice = _amount * userProducts[owner][_id].price * 1 ether;
        require(msg.value >= totalPrice, "Insufficient funds sent");

        Product memory item = Product(_amount, userProducts[owner][_id].price, userProducts[owner][_id].name);
        userProducts[owner][_id].inStock -= _amount;
        
        userProducts[msg.sender].push(item);

        if (msg.value > totalPrice) {
            uint change = msg.value - totalPrice;
            payable(msg.sender).transfer(change);
    }

    uint balance = address(this).balance;
    payable(owner).transfer(balance);
    }
}
