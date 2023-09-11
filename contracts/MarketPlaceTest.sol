// SPDX-License-Identifier: MIT

//TODO добавить поставщика
// Поставщик->Магазин->Пользователь*2
 
pragma solidity ^0.8.0;

contract MarketPlace {
    address public owner;
    address public supplier;
    enum Role { User, Market, Supplier }

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

    
    modifier AccessControl(Role _role, address _shop){
        require(users[msg.sender].role == _role, unicode"");
        require(msg.sender == _shop, unicode"Магазин не соответсвует отправителю");
        _;
    }


    function addItemsSupplier(uint _inStock, uint _price, string calldata _name) public{
        supplier = msg.sender;
        users[supplier] = User(Role.Supplier);
        Product memory item = Product(_inStock, _price / 2, _name);
        userProducts[msg.sender].push(item);
        //TODO сделать поддержку 3х и боллее магазинов
    }

    function makeMarket() public  {
        users[msg.sender] = User(Role.Market);
    }
    
    function addItems(address _shop, uint _inStock, uint _price, string calldata _name) public AccessControl(Role.Market, _shop) {
        Product memory item = Product(_inStock, _price, _name);
        userProducts[_shop].push(item);
    }

    function refillStore(address _shop, uint _productId, uint _amount) public payable AccessControl(Role.Market, _shop){
        require(_amount > 0, "Purchase amount must be greater than 0");
        require(_productId < userProducts[_shop].length, "Invalid product ID");

        uint totalPrice;
        uint price;
        string memory targetName = userProducts[_shop][_productId].name;

        // targetName ВОЗВРАЩАЕТ НЕИЗВЕСТНО, ПРОВЕРИТЬ, В ЧЁМ ПРОБЛЕМА!!!!

        for(uint i = 0; i< userProducts[supplier].length; i++){
            if (keccak256(bytes(targetName)) == keccak256(bytes(userProducts[supplier][i].name))){
                price = userProducts[supplier][i].price;
                totalPrice = price * _amount * 1 ether;
                require(msg.value >= totalPrice, "Insufficient funds sent");
                userProducts[supplier][i].inStock-=_amount;
                userProducts[_shop][_productId].inStock += _amount;   
            }
        }

        if (msg.value > totalPrice) {
            uint change = msg.value - totalPrice;
            payable(msg.sender).transfer(change);
        }

    }

    function purchase(address _shop, uint _amount, uint _id) public payable {
        if (users[msg.sender].role == Role.User) {
            users[msg.sender] = User( Role.User);
        }
        
        require(_amount > 0, "Purchase amount must be greater than 0");
        require(_id < userProducts[_shop].length, "Invalid product ID");
        require(_amount <= userProducts[_shop][_id].inStock, "Not enough stock available");

        uint totalPrice = _amount * userProducts[_shop][_id].price * 1 ether;
        require(msg.value >= totalPrice, "Insufficient funds sent");

        // Проверяем наличие продукта у пользователя
        bool productExists = false;
        for (uint i = 0; i < userProducts[msg.sender].length; i++) {
            if (keccak256(bytes(userProducts[msg.sender][i].name)) == keccak256(bytes(userProducts[_shop][_id].name))) {
                userProducts[msg.sender][i].inStock += _amount;
                productExists = true;
                break; // Выходим из цикла, так как продукт найден
            }
        }

        if (!productExists) {
            // Если продукт не найден, добавляем его
            Product memory newItem = Product(_amount, userProducts[_shop][_id].price, userProducts[_shop][_id].name);
            userProducts[msg.sender].push(newItem);
        }

        userProducts[_shop][_id].inStock -= _amount;

        if (msg.value > totalPrice) {
            uint change = msg.value - totalPrice;
            payable(msg.sender).transfer(change);
        }

        uint balance = address(this).balance;
        payable(_shop).transfer(balance);
        }

}
