// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.21;

contract MarketPlace {
    enum Role { User, Market, Supplier }
    enum Status { Created, Prepairing, Canceled, Complete}

    
    Ticket[] public tickets;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    struct DeliveryOrder {
        address userAddr;
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
        Role role;
        uint balance;
    }

    // Сделать маппинги ролей и взаимодествовать только с ними
    struct Product {
        address userAddress;
        uint inStock;
        uint price;
        string name;
        uint expDate;
    }


    mapping(address => User) public users;
    mapping(address => Product[]) public userProducts;
    mapping(address => Product[]) public marketProducts;
    mapping(address => Product[]) public supplierProducts;
    mapping(string => address) public referrals;
    mapping(address => DeliveryOrder[]) deliveryOrders;


    modifier OnlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    modifier AccessControl(Role _role, address _shop){
        require(users[msg.sender].role == _role, unicode"Ваша роль не позволяет это изменять");
        require(msg.sender == _shop, unicode"Магазин не соответсвует отправителю");
        _;
    }

    // Делать юзера и после делать тикет на смену роли. Вместе с юзером пушить 3 структуры для ролей

    function makeUser() public {
        users[msg.sender] = User(Role.User, 0);
    }

    function makeSupplier() public {
        users[msg.sender] = User(Role.Supplier, 0);
    }

    function makeMarket() public  {
        users[msg.sender] = User(Role.Market, 0);
    }

    function approveChangeRole(uint _idTicket) public OnlyOwner {
        address userAddr = tickets[_idTicket].userAddr;
        Role changedRole = tickets[_idTicket].role;
        users[userAddr].role = changedRole;
        // userProducts[userAddr][0] = productArrayItems[userAddr][1];
    }

    function changeRole(Role _role) public {
        tickets.push(Ticket(msg.sender, _role));
    }

    function randMod(uint _modulus) public view returns(uint) {   
        uint randNonce;
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % _modulus;
    }

    function toUpper(string memory input) public pure returns (string memory) {
        bytes memory inputBytes = bytes(input);
        for (uint256 i = 0; i < inputBytes.length; i++) {
            // Check if the character is a lowercase letter (ASCII value 97 to 122).
            if (uint8(inputBytes[i]) >= 97 && uint8(inputBytes[i]) <= 122) {
                // Convert the lowercase letter to uppercase by subtracting 32 from its ASCII value.
                inputBytes[i] = bytes1(uint8(inputBytes[i]) - 32);
            }
        }
        return string(inputBytes);
    }

    function genRef(string memory _nameRef, address _user) public {
        require(msg.sender != _user);
        referrals[_nameRef] = _user;
    } 

    function makeDelivery(address _shop, uint _productId, uint _amount) public {
        require(_amount > 0, "Purchase amount must be greater than 0");
        require(_productId < marketProducts[_shop].length, "Invalid product ID");
        string memory productName = marketProducts[_shop][_productId].name;
        string memory trackNumber = string.concat("AA",productName,"BB");
        trackNumber = toUpper(trackNumber);
        DeliveryOrder memory order = DeliveryOrder(msg.sender, Status.Prepairing, trackNumber, _productId, _amount);
        deliveryOrders[msg.sender].push(order);
    }

    function addItemsSupplier(uint _inStock, uint _price, string calldata _name, uint _expDate, address _addressSupp) public AccessControl(Role.Supplier, _addressSupp) {
        Product memory item = Product(_addressSupp, _inStock, _price / 2, _name, _expDate);
        supplierProducts[_addressSupp].push(item);
    }

    function addItemsMarket(uint _inStock, uint _price, string calldata _name, uint _expDate) public {
        Product memory item = Product(msg.sender, _inStock, _price / 2, _name, _expDate);
        marketProducts[msg.sender].push(item);
    }
    

    function refillStore(address _shop, uint _productId, uint _amount, address _supplier) public payable AccessControl(Role.Market, _shop) {
        require(_amount > 0, "Purchase amount must be greater than 0");
        require(_productId < supplierProducts[_supplier].length, "Invalid product ID");
        uint price = supplierProducts[_supplier][_productId].price;
        uint totalPrice = price * _amount * 1 ether;
        require(msg.value >= totalPrice, "Insufficient funds sent");
        string memory targetName = supplierProducts[_supplier][_productId].name;
        bool productExists = false;

        for(uint i = 0; i< marketProducts[_shop].length; i++){
            if (keccak256(bytes(targetName)) == keccak256(bytes(marketProducts[_shop][i].name))){
                marketProducts[_shop][i].inStock += _amount;
                productExists = true;
                break;   
            }
        }

        if (!productExists){
            Product memory newItem = Product(_supplier, _amount, price, targetName, supplierProducts[_supplier][_productId].expDate);
            marketProducts[_shop].push(newItem);
        }

        supplierProducts[_supplier][_productId].inStock -= _amount;

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

    }

    function refund(address _shop, uint _productId) public {
        require(userProducts[msg.sender][_productId].expDate > marketProducts[_shop][_productId].expDate);
        uint totalRefSum =  userProducts[msg.sender][_productId].inStock * marketProducts[_shop][_productId].price * 1 ether;
        marketProducts[_shop][_productId].inStock += userProducts[msg.sender][_productId].inStock;
        delete userProducts[msg.sender][_productId];
        users[_shop].balance -= totalRefSum;
        payable(msg.sender).transfer(totalRefSum);
    }

    function purchase(address _shop, uint _amount, uint _id, string memory _ref ) public payable {
        if (users[msg.sender].role == Role.User) {
            users[msg.sender] = User( Role.User, 0);
        }
        
        require(_amount > 0, "Purchase amount must be greater than 0");
        require(_id < marketProducts[_shop].length, "Invalid product ID");
        require(_amount <= marketProducts[_shop][_id].inStock, "Not enough stock available");

        uint totalPrice = _amount * marketProducts[_shop][_id].price * 1 ether;

        if (referrals[_ref] == msg.sender) {
            totalPrice = (totalPrice * 90 / 100);
            referrals[_ref] = address(0);
        }

        require(msg.value >= totalPrice, "Insufficient funds sent");
        bool productExists = false;

        for (uint i = 0; i < userProducts[msg.sender].length; i++) {
            if (keccak256(bytes(userProducts[msg.sender][i].name)) == keccak256(bytes(userProducts[_shop][_id].name))) {
                userProducts[msg.sender][i].inStock += _amount;
                productExists = true;
                break; 
            }
        }

        if (!productExists) {
            Product memory newItem = Product(msg.sender, _amount, marketProducts[_shop][_id].price, marketProducts[_shop][_id].name, randMod(1000));
            userProducts[msg.sender].push(newItem);
        }

        marketProducts[_shop][_id].inStock -= _amount;
        users[_shop].balance = totalPrice;

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function withdrawBal(address _shop) public {
        payable(_shop).transfer(users[_shop].balance);
    }
}
