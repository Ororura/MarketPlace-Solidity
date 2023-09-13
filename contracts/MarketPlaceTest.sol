// SPDX-License-Identifier: MIT

// TODO: Сделать смену роли для пользователей. Сделать подтверждение смены роли 
 
pragma solidity ^0.8.0;

contract MarketPlace {
    enum Role { User, Market, Supplier }
    Ticket[] public tickets;
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    struct Ticket {
        address userAddr;
        Role role;
    }

    struct User {
        Role role;
        uint balance;
    }

    struct Product {
        uint inStock;
        uint price;
        string name;
        uint expDate;
    }

    mapping(address => User) public users;
    mapping(address => Product[]) public userProducts;
    mapping(string => address) public referrals;


    modifier OnlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    modifier AccessControl(Role _role, address _shop){
        require(users[msg.sender].role == _role, unicode"");
        require(msg.sender == _shop, unicode"Магазин не соответсвует отправителю");
        _;
    }

    function makeUser() public {
        users[msg.sender] = User(Role.User, 0);
    }

    function approveChangeRole(uint _idTicket) public OnlyOwner{
        address userAddr = tickets[_idTicket].userAddr;
        Role changedRole = tickets[_idTicket].role;
        users[userAddr].role = changedRole;
    }

    function changeRole(Role _role) public{
        // require(uint(users[msg.sender].role) >= 0);
        // users[msg.sender].role = _role;
        tickets.push(Ticket(msg.sender, _role));
    }

    function randMod(uint _modulus) public view returns(uint)
    {   
        uint randNonce;
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % _modulus;
    }

    function genRef(string memory _nameRef, address _user) public {
        require(msg.sender != _user);
        referrals[_nameRef] = _user;
    } 

    function addItemsSupplier(uint _inStock, uint _price, string calldata _name, uint _expDate, address _addressSupp) public AccessControl(Role.Supplier, _addressSupp) {
        Product memory item = Product(_inStock, _price / 2, _name, _expDate);
        userProducts[_addressSupp].push(item);
    }
    
    function makeSupplier() public {
        users[msg.sender] = User(Role.Supplier, 0);
    }

    function makeMarket() public  {
        users[msg.sender] = User(Role.Market, 0);
    }
    
    function addItems(address _shop, uint _inStock, uint _price, string calldata _name, uint _expDate) public AccessControl(Role.Market, _shop) {
        Product memory item = Product(_inStock, _price, _name, _expDate);
        userProducts[_shop].push(item);
    }

    function showProductsSupl(uint _productId, address _supplier) public view returns(uint) {
        return userProducts[_supplier][_productId].inStock;
    }

    function refillStore(address _shop, uint _productId, uint _amount, address _supplier) public payable AccessControl(Role.Market, _shop){
        require(_amount > 0, "Purchase amount must be greater than 0");
        require(_productId < userProducts[_supplier].length, "Invalid product ID");

        uint totalPrice;
        uint price;
        string memory targetName = userProducts[_supplier][_productId].name;
        //Payable, чё то не так. Надо отправлять эфир или нет 
        for(uint i = 0; i< userProducts[_shop].length; i++){
            if (keccak256(bytes(targetName)) == keccak256(bytes(userProducts[_shop][i].name))){
                price = userProducts[_supplier][i].price;
                totalPrice = price * _amount * 1 ether;
                require(msg.value >= totalPrice, "Insufficient funds sent");
                userProducts[_supplier][_productId].inStock-=_amount;
                userProducts[_shop][i].inStock += _amount;   
            }
            else {
                uint inStock = userProducts[_supplier][_productId].inStock;
                uint expDate = userProducts[_supplier][_productId].expDate;
                Product memory newItem = Product(inStock, price, targetName, expDate);
                userProducts[_shop].push(newItem);
            }
        }

        if (msg.value > totalPrice) {
            uint change = msg.value - totalPrice;
            payable(msg.sender).transfer(change);
        }

    }

    function refund(address _shop, uint _productId) public {
        uint userExp = userProducts[msg.sender][_productId].expDate;
        uint shopExp = userProducts[_shop][_productId].expDate;
        require(userExp > shopExp);
        uint totalRefSum =  userProducts[msg.sender][_productId].inStock * userProducts[_shop][_productId].price * 1 ether;
        userProducts[_shop][_productId].inStock += userProducts[msg.sender][_productId].inStock;
        delete userProducts[msg.sender][_productId];
        users[_shop].balance -= totalRefSum;
        payable(msg.sender).transfer(totalRefSum);


    }

    function purchase(address _shop, uint _amount, uint _id, string memory _ref ) public payable {
        if (users[msg.sender].role == Role.User) {
            users[msg.sender] = User( Role.User, 0);
        }
        
        require(_amount > 0, "Purchase amount must be greater than 0");
        require(_id < userProducts[_shop].length, "Invalid product ID");
        require(_amount <= userProducts[_shop][_id].inStock, "Not enough stock available");

        uint totalPrice = _amount * userProducts[_shop][_id].price * 1 ether;

        if (referrals[_ref] == msg.sender) {
            totalPrice = (totalPrice * 90 / 100);
            referrals[_ref] = address(0);
        }
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

        // Если продукт не найден, добавляем его
        if (!productExists) {

            //Реализовать генерацию чисел 
            Product memory newItem = Product(_amount, userProducts[_shop][_id].price, userProducts[_shop][_id].name, randMod(1000));
            userProducts[msg.sender].push(newItem);
        }

        userProducts[_shop][_id].inStock -= _amount;

        if (msg.value > totalPrice) {
            uint change = msg.value - totalPrice;
            payable(msg.sender).transfer(change);
        }
        users[_shop].balance = totalPrice;

        }

    function withdrawBal(address _shop) public {
        uint balance = users[_shop].balance;
        payable(_shop).transfer(balance);
    }
}
