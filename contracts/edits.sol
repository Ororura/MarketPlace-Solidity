// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.21;
/* 
TODO: 
1) Пофиксить проблему с id товара при возврате товара (возможно возврате, не помню). Решение: Оставить по дфеолту 0 и при покупки ставить id в магазине. 
2) Добавить Логин и фио к юзеру
3) Сделать маппинг из паролей
4) Попробовать убрать маппинги магазинов, супплаеров и оставить один. (Добавить адресс к продукту) обращаемся к  
ПРОБЛЕМА:  
*/


contract MarketPlace {
    enum Role { User, Market, Supplier } // Роли пользователей 
    enum Status { Created, Prepairing, Canceled, Complete} // Статусы создания доставки  


    struct DeliveryOrder { // Структура заказов 
        address userAddr;
        address shop;
        Status status;
        string trackNumber;
        uint productId;
        uint amount;
    }

    struct Ticket { // Структура тикетов на смену ролей 
        address userAddr;
        Role role;
    }

    struct User { // Структура пользователей
        // добавить логин, фио
        string login;
        string firstName;
        string lastName;
        Role role;
        uint balance;
    }

    struct Product { // Структура продукта
        uint id;
        // shopAddress
        address userAddress;
        uint inStock;
        uint price;
        string name;
        uint expDate;
    }

    Ticket[] public tickets; // Массив из тикетов на смену ролей. 
    address public owner; 
    DeliveryOrder[] public deliveryOrders; // Список заказов на доставку 

    mapping(address => User) public users;  // Маппинг всех пользователей 

    // 1 маппинг, чтобы достать продукты каждого юзера

    mapping(address => Product[]) public userProducts; // Инвентарь продуктов обычного покупателя

    mapping(address => Product[]) public marketProducts; // Инвентарь продуктов магазина 
    mapping(address => Product[]) public supplierProducts; // Инвентарь поставщиков

    mapping(string => address) public referrals; // Рефералка привязанная к пользователю, которого указали при создании
    // хэшированный пароль
    mapping(address => bytes32) public passwords;

    constructor() {
        owner = msg.sender;
    }


    modifier OnlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    modifier AccessControl(Role _role){
        require(users[msg.sender].role == _role, "Your role does not allow this change");
        _;
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

    // регистрация, проверка на существующего пользователя по адресу, по логину

    // проверка совпали ли логин пароль, возвращается структура

    // function makeUser() external { // Создание покупателя
    //     users[msg.sender] = User(Role.User, 0);
    // }

    function getProducts(address _shop) public view returns(Product[] memory){
        return marketProducts[_shop];
    }

    // function makeSupplier() external  { // Создание поставщика
    //     users[msg.sender] = User(Role.Supplier, 0);
    // }

    // function makeMarket() external   { // Создание магазина 
    //     users[msg.sender] = User(Role.Market, 0);
    // }

    function approveChangeRole(uint _idTicket) external  OnlyOwner { // Подтверждение смены роли для пользователя ( Подтверждать смену может только ВЛАДЕЛЦ контракта). Передается id тикета
        address userAddr = tickets[_idTicket].userAddr;
        Role changedRole = tickets[_idTicket].role;
        users[userAddr].role = changedRole;
    }

    function changeRole(Role _role) public { // Создание тикета на смену роли. Указываем роль, которую хотим сменить
    // сделать проверку, чтобы человек не мог отправить 2 раза тикет 
        tickets.push(Ticket(msg.sender, _role));
    }

    function randMod(uint _modulus) public view returns(uint) { // Генерация рандомного числа 
        uint randNonce;
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % _modulus;
    }

    function toUpper(string memory input) public pure returns (string memory) { // Перевод в заглавные буквы 
        bytes memory inputBytes = bytes(input);
        for (uint256 i = 0; i < inputBytes.length; i++) {
            if (uint8(inputBytes[i]) >= 97 && uint8(inputBytes[i]) <= 122) {
                inputBytes[i] = bytes1(uint8(inputBytes[i]) - 32);
            }
        }
        return string(inputBytes);
    }

    function genRef(string memory _nameRef, address _user) external { // Создание рефералки для скидки. Указываем название рефералки и пользователя, который может её использовать.
        referrals[_nameRef] = _user;
    } 

    function makeDelivery(address _shop, uint _productId, uint _amount) external  { // Заказать доставку продуктов на дом. Указываем магазин, продукт, кол-во.
        require(_amount > 0, "Purchase amount must be greater than 0");
        require(_productId < marketProducts[_shop].length, "Invalid product ID");
        string memory productName = marketProducts[_shop][_productId].name;
        string memory trackNumber = string.concat("AA",productName,"BB");
        trackNumber = toUpper(trackNumber);
        DeliveryOrder memory order = DeliveryOrder(msg.sender, _shop, Status.Prepairing, trackNumber, _productId, _amount);
        deliveryOrders.push(order);
    }

    function approveDelivery(bool _solution, uint _deliveryId) external  AccessControl(Role.Market) {  // Подтведрить доставку со стороны магазина. Указываем решение (true/false) и id доставки 
        if (_solution) {
            deliveryOrders[_deliveryId].status = Status.Prepairing;
        }
        else {
            deliveryOrders[_deliveryId].status = Status.Canceled;
        }
    }

    function acceptDelivery(bool _solution, uint _deliveryId) external  payable AccessControl(Role.User) { // Подтвердить доставку со стороны пользователя (После подтверждения доставки со стороны магазина). Указываем решение (true/false) и id доставки 
        require(deliveryOrders[_deliveryId].status == Status.Prepairing);
        if (_solution) { 
            purchase(deliveryOrders[_deliveryId].shop, deliveryOrders[_deliveryId].amount, _deliveryId, "");
        }
        else {
            deliveryOrders[_deliveryId].status == Status.Canceled;
        }
    }

    function addItemsSupplier(uint _inStock, uint _price, string calldata _name, uint _expDate, address _addressSupp) external  AccessControl(Role.Supplier) { // Добавить товары для поставщика
        Product memory item = Product(0, _addressSupp, _inStock, _price / 2, _name, _expDate);
        supplierProducts[_addressSupp].push(item);
    }

    function addItemsMarket(uint _inStock, uint _price, string calldata _name, uint _expDate) external  AccessControl(Role.Market) { // Добавить товары для магазина (По логике, мы пополняем товары через поставщика. Я добавил эту функцию, чтобы не тратить время во время тестирования)
        Product memory item = Product(0, msg.sender, _inStock, _price, _name, _expDate);
        marketProducts[msg.sender].push(item);
    }
    

    function refillStore(address _shop, uint _productId, uint _amount, address _supplier) external payable AccessControl(Role.Market) { // Пополнить магазин. Указываем магазин, id продукта, кол-во, поставщика
        require(_amount > 0, "Purchase amount must be greater than 0");
        require(_productId < supplierProducts[_supplier].length, "Invalid product ID");
        uint price = supplierProducts[_supplier][_productId].price;
        uint totalPrice = price * _amount; 
        require(msg.value >= totalPrice, "Insufficient funds sent");
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

    

    // Проблема: как нам перебирать mapping
    function refundRequest(address _shop, uint _productId) external  { // Сделать возврат товара. Указываем магазин и id возвращаемого товра. 
        require(userProducts[msg.sender][_productId].expDate > marketProducts[_shop][_productId].expDate);
        uint totalRefSum =  userProducts[msg.sender][_productId].inStock * marketProducts[_shop][_productId].price;
        marketProducts[_shop][_productId].inStock += userProducts[msg.sender][_productId].inStock;
        delete userProducts[msg.sender][_productId];
        users[_shop].balance -= totalRefSum; // при любой покупке, возврате, баланс менять нужно не только у магазина
        payable(msg.sender).transfer(totalRefSum);
    }


    function purchase(address _shop, uint _amount, uint _id, string memory _ref ) public payable { // Покупаем со стороны пользователя у магазина продукты. Указываем магазин, id продукта, кол-во, Рефералку(может использовать только тот, которого указали при создании рефералки)
        // if (users[msg.sender].role == Role.User) {
        //     users[msg.sender] = User( Role.User, 0);
        // }
        
        require(_amount > 0, "Purchase amount must be greater than 0");
        require(_id < marketProducts[_shop].length, "Invalid product ID");
        require(_amount <= marketProducts[_shop][_id].inStock, "Not enough stock available");
        
        uint totalPrice = _amount * marketProducts[_shop][_id].price;
        if (referrals[_ref] == msg.sender) {
            totalPrice = (totalPrice * 90 / 100);
            referrals[_ref] = address(0);
        }

        require(msg.value >= totalPrice, "Insufficient funds sent");
        bool productExists = false;

        for (uint i = 0; i < userProducts[msg.sender].length; i++) {
            if (keccak256(abi.encode(userProducts[msg.sender][i].name)) == keccak256(abi.encode(userProducts[_shop][_id].name))) {
                userProducts[msg.sender][i].inStock += _amount;
                productExists = true;
                break; 
            }
        }

        if (!productExists) {
            userProducts[msg.sender].push(Product(_id, _shop, _amount, msg.value, marketProducts[_shop][_id].name, randMod(1000)));
        }

        marketProducts[_shop][_id].inStock -= _amount;
        users[_shop].balance += totalPrice; // -> msg.value

    }

    function withdrawBal() public AccessControl(Role.Market) { // Выводим баланса с контракта. 
        payable(msg.sender).transfer(users[msg.sender].balance);
        users[msg.sender].balance = 0;
    }
}
