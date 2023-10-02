// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.21;
import "hardhat/console.sol";
/* 
TODO: 
1) Сделать проверку на имеющегося пользователя во время регистрации.
4) Попробовать убрать маппинги магазинов, супплаеров и оставить один. (Добавить адресс к продукту) обращаемся к   
ПРОБЛЕМА:  
*/


contract MarketPlace {
    enum Role { User, Market, Supplier }
    enum Status { Created, Prepairing, Canceled, Complete} 

    struct DeliveryOrder {
        address userAddr;
        address shop;
        Status status;
        string trackNumber;
        uint productId;
        uint amount;
    }

    struct Ticket { 
        address userAddr;
        Role role;
    }

    struct User {
        string login;
        string firstName;
        string lastName;
        Role role;
        uint balance;
    }

    struct Product {
        uint id;
        address userAddress;
        uint inStock;
        uint price;
        string name;
        uint expDate;
    }

    DeliveryOrder[] public deliveryOrders;
    Ticket[] public tickets;
    address public owner; 

    mapping(address => bool) public hasRoleChangeRequest;
    mapping(address => User) public users;
    // 1 маппинг, чтобы достать продукты каждого юзера
    mapping(address => Product[]) public userProducts;
    mapping(address => Product[]) public marketProducts;
    mapping(address => Product[]) public supplierProducts; 
    mapping(address => string) public usersReferral; 
    mapping(address => bytes32) public passwords;

    constructor() {
        owner = msg.sender;
    }


    modifier OnlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    modifier AccessControl(Role _role){
        require(users[msg.sender].role == _role, unicode"Ваша роль не позволяет это использовать");
        _;
    }

    function getProducts(uint _id) external view returns(Product memory) {
        return userProducts[msg.sender][_id];
    }

    function getReferrals() external view returns(string memory) {
        return usersReferral[msg.sender];
    }

    

    // !!!!!!!! Привязан ли адресс к аккаутну пользователя? 
    function registration(string memory _login, string memory _firstName, string memory _lastName, string memory _password) external {
        users[msg.sender] = User(_login, _firstName, _lastName, Role.User, 0);
        passwords[msg.sender] = keccak256(abi.encode(_password));
    }

    function login(string memory _login, string memory _password) external view returns(User memory) {
        string memory storedLogin = users[msg.sender].login;
        require(keccak256(abi.encodePacked(_login)) == keccak256(abi.encodePacked(storedLogin)));
        require(keccak256(abi.encode(_password)) == passwords[msg.sender]);
        return users[msg.sender];
    }

    function getProducts(address _shop) public view returns(Product[] memory){
        return marketProducts[_shop];
    }

    // function makeUser() external { 
    //     users[msg.sender] = User("test", "test", "test",Role.User, 0);
    // }

    // function makeSupplier() external  { 
    //     users[msg.sender] = User("test", "test", "test", Role.Supplier, 0);
    // }

    // function makeMarket() external   { 
    //     users[msg.sender] = User("test", "test", "test", Role.Market, 0);
    // }

    function approveChangeRole(uint _idTicket, bool _status) external OnlyOwner { 
        require(_idTicket < tickets.length, unicode"Неверный id");
        address userAddr = tickets[_idTicket].userAddr;
        Role changedRole = tickets[_idTicket].role;

        if (_status) {
            users[userAddr].role = changedRole;
        }

        hasRoleChangeRequest[userAddr] = false;
        delete tickets[_idTicket];
    }


    function changeRole(Role _role) public {
        require(!hasRoleChangeRequest[msg.sender], unicode"Вы уже создали запрос");
        tickets.push(Ticket(msg.sender, _role));
        hasRoleChangeRequest[msg.sender] = true;
    }


    function randMod(uint _modulus) public view returns(uint) { 
        uint randNonce;
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % _modulus;
    }

    function genRef(string memory _nameRef, address _user) external {
        usersReferral[_user] = _nameRef;
    } 

    function makeDelivery(address _shop, uint _productId, uint _amount) external  {
        require(_amount > 0, unicode"Кол-во продуктов должно быть больше 0");
        require(_productId < marketProducts[_shop].length, unicode"Неправильный id продукта");
        string memory productName = marketProducts[_shop][_productId].name;
        string memory trackNumber = string.concat("AA",productName,"BB");
        DeliveryOrder memory order = DeliveryOrder(msg.sender, _shop, Status.Prepairing, trackNumber, _productId, _amount);
        deliveryOrders.push(order);
    }

    function approveDelivery(bool _solution, uint _deliveryId) external  AccessControl(Role.Market) { 
        if (_solution) {
            deliveryOrders[_deliveryId].status = Status.Prepairing;
        }
        else {
            deliveryOrders[_deliveryId].status = Status.Canceled;
        }
    }

    function acceptDelivery(bool _solution, uint _deliveryId) external  payable AccessControl(Role.User) { 
        require(deliveryOrders[_deliveryId].status == Status.Prepairing);
        if (_solution) { 
            purchase(deliveryOrders[_deliveryId].shop, deliveryOrders[_deliveryId].amount, _deliveryId, "");
        }
        else {
            deliveryOrders[_deliveryId].status == Status.Canceled;
        }
    }

    function addItemsSupplier(uint _inStock, uint _price, string calldata _name, uint _expDate, address _addressSupp) external  AccessControl(Role.Supplier) {
        Product memory item = Product(0, _addressSupp, _inStock, _price / 2, _name, _expDate);
        supplierProducts[_addressSupp].push(item);
    }

    function addItemsMarket(uint _inStock, uint _price, string calldata _name, uint _expDate) external  AccessControl(Role.Market) { 
        Product memory item = Product(0, msg.sender, _inStock, _price, _name, _expDate);
        marketProducts[msg.sender].push(item);
    }
    

    function refillStore(address _shop, uint _productId, uint _amount, address _supplier) external payable AccessControl(Role.Market) {
        require(_amount > 0, unicode"Кол-во продуктов должно быть больше 0");
        require(_productId < supplierProducts[_supplier].length, unicode"Неправильный id продукта");
        uint price = supplierProducts[_supplier][_productId].price;
        uint totalPrice = price * _amount; 
        require(msg.value >= totalPrice, unicode"Недостаточно отправленной валюты");
        string memory targetName = supplierProducts[_supplier][_productId].name;
        bool productExists = false;

        for(uint i = 0; i< marketProducts[_shop].length; i++){
            if (keccak256(abi.encode(targetName)) == keccak256(abi.encode(marketProducts[_shop][i].name))){
                marketProducts[_shop][i].inStock += _amount;
                productExists = true;
                break;   
            }
        }

        if (!productExists){
            Product memory newItem = Product(0, _supplier, _amount, price, targetName, supplierProducts[_supplier][_productId].expDate);
            marketProducts[_shop].push(newItem);
        }

        supplierProducts[_supplier][_productId].inStock -= _amount;

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice); 
        }

    }

    function refundRequest(address _shop, uint _productId) external {
        uint idArray;
        bool isFound = false;

        for(uint i; i < userProducts[msg.sender].length; i++) {
            if(keccak256(abi.encode(userProducts[msg.sender][i].name)) == keccak256(abi.encode(marketProducts[_shop][_productId].name))) {
                idArray = i;
                isFound = true;
                break;
            }
        }

        require(isFound);
        require(userProducts[msg.sender][idArray].expDate > marketProducts[_shop][_productId].expDate);
        uint totalRefSum =  userProducts[msg.sender][idArray].inStock * marketProducts[_shop][_productId].price;
        marketProducts[_shop][_productId].inStock += userProducts[msg.sender][idArray].inStock;
        delete userProducts[msg.sender][idArray];
        users[_shop].balance -= totalRefSum;
        payable(msg.sender).transfer(totalRefSum);
    }

    function purchase(address _shop, uint _amount, uint _id, string memory _ref ) public payable {
        require(_amount > 0, unicode"Кол-во покупок должно быть больше 0");
        require(_id < marketProducts[_shop].length, unicode"Неправильный id продукта");
        require(_amount <= marketProducts[_shop][_id].inStock, unicode"Недостаточно продуктов в наличии");
        uint totalPrice = _amount * marketProducts[_shop][_id].price;
        
        if (keccak256(abi.encodePacked(usersReferral[msg.sender])) == keccak256(abi.encodePacked(_ref))) {
            totalPrice = (totalPrice * 90 / 100);
            delete usersReferral[msg.sender];
        }

        require(msg.value >= totalPrice, unicode"Недостаточно отправленной валюты");
        bool productExists = false;

        for (uint i = 0; i < userProducts[msg.sender].length; i++) {
            if (keccak256(abi.encode(userProducts[msg.sender][i].name)) == keccak256(abi.encode(marketProducts[_shop][_id].name))) {
                userProducts[msg.sender][i].inStock += _amount;
                productExists = true;
                break; 
            }
        }

        if (!productExists) {
            userProducts[msg.sender].push(Product(_id, _shop, _amount, msg.value, marketProducts[_shop][_id].name, randMod(1000)));
        }

        marketProducts[_shop][_id].inStock -= _amount;
        users[_shop].balance += totalPrice; 

    }

    function withdrawBal() public AccessControl(Role.Market) { 
        payable(msg.sender).transfer(users[msg.sender].balance);
        users[msg.sender].balance = 0;
    }
}