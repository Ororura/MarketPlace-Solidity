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
        users[owner] = User(0, Role.Market, new Product[](0));
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

    // function purchaseBread(uint _amount, uint _id) public payable {
    //     require(_amount <=users[owner].product[_id].inStock); // Покупают меньше, чем есть в наличии
    //     require(_amount > 0); //Пользователь покупает больше 0
    //     uint totalPrice = _amount * users[owner].product[_id].price * 1 ether;
    //     require(msg.value >= totalPrice); // Отправленных денег больше, чем итоговая цена
        
    //     Product memory 
    //     users[owner].product[0].inStock -= _amount;

    //     users[msg.sender].
    //     users[msg.sender].breadsPurchased += _amount;

    //     if (msg.value > totalPrice) {
    //         uint change = msg.value - totalPrice;
    //         payable(msg.sender).transfer(change);
    //     }

    //     uint balance = address(this).balance;
    //     payable(owner).transfer(balance);
    // }
}