// SPDX-License-Identifier: MIT

//TODO добавить поставщика
// Поставщик->Магазин->Пользователь*2
 
pragma solidity ^0.8.0;

contract MarketPlace {
    address public owner;
    enum Role { User, Market }

    struct User {
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
        users[owner] = User(Role.Market);
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
        if (users[msg.sender].role == Role.User) {
            users[msg.sender] = User( Role.User);
        }
        
        require(_amount > 0, "Purchase amount must be greater than 0");
        require(_id < userProducts[owner].length, "Invalid product ID");
        require(_amount <= userProducts[owner][_id].inStock, "Not enough stock available");

        uint totalPrice = _amount * userProducts[owner][_id].price * 1 ether;
        require(msg.value >= totalPrice, "Insufficient funds sent");

        // Проверяем наличие продукта у пользователя
        bool productExists = false;
        for (uint i = 0; i < userProducts[msg.sender].length; i++) {
            if (keccak256(bytes(userProducts[msg.sender][i].name)) == keccak256(bytes(userProducts[owner][_id].name))) {
                userProducts[msg.sender][i].inStock += _amount;
                productExists = true;
                break; // Выходим из цикла, так как продукт найден
            }
        }

        if (!productExists) {
            // Если продукт не найден, добавляем его
            Product memory newItem = Product(_amount, userProducts[owner][_id].price, userProducts[owner][_id].name);
            userProducts[msg.sender].push(newItem);
        }

        userProducts[owner][_id].inStock -= _amount;

        if (msg.value > totalPrice) {
            uint change = msg.value - totalPrice;
            payable(msg.sender).transfer(change);
        }

        uint balance = address(this).balance;
        payable(owner).transfer(balance);
        }

}
