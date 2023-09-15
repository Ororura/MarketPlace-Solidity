// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.21;

contract MarketPlace {
    enum Role { User, Market, Supplier }

    
    Ticket[] public tickets;
    address public owner;

    constructor() {
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
    mapping(address => Product[]) public productItems;


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
        productItems[msg.sender].push(Product(13, 0, " ", 0));
        productItems[msg.sender].push(Product(28, 0, " ", 0));
        productItems[msg.sender].push(Product(52, 0, " ", 0));
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
        userProducts[msg.sender][0] = productItems[msg.sender][uint(changedRole)];
    }

    function changeRole(Role _role) public {
        tickets.push(Ticket(msg.sender, _role));
    }

    function randMod(uint _modulus) public view returns(uint) {   
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
    

    function refillStore(address _shop, uint _productId, uint _amount, address _supplier) public payable AccessControl(Role.Market, _shop) {
        require(_amount > 0, "Purchase amount must be greater than 0");
        require(_productId < userProducts[_supplier].length, "Invalid product ID");
        uint price = userProducts[_supplier][_productId].price;
        uint totalPrice = price * _amount * 1 ether;
        require(msg.value >= totalPrice, "Insufficient funds sent");
        string memory targetName = userProducts[_supplier][_productId].name;
        bool productExists = false;

        for(uint i = 0; i< userProducts[_shop].length; i++){
            if (keccak256(bytes(targetName)) == keccak256(bytes(userProducts[_shop][i].name))){
                userProducts[_shop][i].inStock += _amount;
                productExists = true;
                break;   
            }
        }

        if (!productExists){
            Product memory newItem = Product(_amount, price, targetName, userProducts[_supplier][_productId].expDate);
            userProducts[_shop].push(newItem);
        }

        userProducts[_supplier][_productId].inStock -= _amount;

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

    }

    function refund(address _shop, uint _productId) public {
        require(userProducts[msg.sender][_productId].expDate > userProducts[_shop][_productId].expDate);
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
        bool productExists = false;

        for (uint i = 0; i < userProducts[msg.sender].length; i++) {
            if (keccak256(bytes(userProducts[msg.sender][i].name)) == keccak256(bytes(userProducts[_shop][_id].name))) {
                userProducts[msg.sender][i].inStock += _amount;
                productExists = true;
                break; 
            }
        }

        if (!productExists) {
            Product memory newItem = Product(_amount, userProducts[_shop][_id].price, userProducts[_shop][_id].name, randMod(1000));
            userProducts[msg.sender].push(newItem);
        }

        userProducts[_shop][_id].inStock -= _amount;
        users[_shop].balance = totalPrice;

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function withdrawBal(address _shop) public {
        payable(_shop).transfer(users[_shop].balance);
    }
}
