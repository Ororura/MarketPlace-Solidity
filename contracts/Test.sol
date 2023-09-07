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
}
