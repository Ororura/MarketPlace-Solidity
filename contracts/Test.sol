// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test{
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

    constructor(){
        owner = msg.sender; 
    }

    function addItems(uint _inStock, uint _price, string calldata _name) public {
        Product memory item = Product(_inStock, _price, _name);
        users[owner].product.push(item);
    }

    function showItems() public view returns(Product[] memory) {
        return users[owner].product;
    }

    function showInStock() public view returns(uint) {
        return users[owner].product[0].inStock;
    }

    // function purchaseBread(uint _amount, uint id) public payable {
    //     require(_amount <=users[owner].product.inStock); // Сделать проверку на кол-во покупок
    //     require(_amount > 0); //Пользователь покупает больше 0
    //     uint totalPrice = _amount * markets[owner].breadPrice;
    //     require(msg.value >= totalPrice);

    //     markets[owner].breadInStock -= _amount;
    //     users[msg.sender].breadsPurchased += _amount;

    //     if (msg.value > totalPrice) {
    //         uint change = msg.value - totalPrice;
    //         payable(msg.sender).transfer(change);
    //     }

    //     uint balance = address(this).balance;
    //     payable(owner).transfer(balance);
    // }
}