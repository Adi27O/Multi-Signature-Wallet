//SPDX-License-Identifier: MIT
pragma solidity >= 0.8.2 < 0.9.0;

contract MultiSig {
    address[] public owners;            //peoples controlling sc
    uint public numConfirmationsRequired;  

    struct Transaction{
        address to;
        uint value;
        bool executed;
    }
    //nested mapping to know whether txn is confirmed or not
    mapping(uint=>mapping(address=>bool)) isConfirmed;
    Transaction[] public transactions;

    event TransactionSubmitted(uint transactionId, address sender, address receiver, uint amount);
    event TransactionConfirmed(uint transactionId);
    event TransactionExecuted(uint transactionId);

    constructor(address[] memory _owners, uint _numConfirmationsRequired){
        require(_owners.length>1,"No of owners must be greater than 1");
        require(_numConfirmationsRequired>0 && _numConfirmationsRequired<= _owners.length,"No of confirmations is not in sync with no of owners");

        for(uint i =0; i<=_owners.length; i++) {
            require(_owners[i]!= address(0),"invalid owner");
            owners.push(_owners[i]);
        }
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    function submitTransaction(address _to) public payable{
        require(_to != address(0), "Invalid address");
        require(msg.value>0, "Transfer amount must be greater than 0");
        uint transactionId = transactions.length;
        transactions.push(Transaction({to :_to, value:msg.value,executed:false}));
        emit TransactionSubmitted(transactionId, msg.sender,_to,msg.value);
    }

    function confirmTransaction(uint _transactionId) public {
        require(_transactionId<transactions.length,"Invalid transaction id");
        require(isConfirmed[_transactionId][msg.sender],"Transaction is already confirmed by owner");
        isConfirmed[_transactionId][msg.sender]= true;
        emit TransactionConfirmed(_transactionId);
        if(isTransactionConfirmed(_transactionId)){
            executeTransaction(_transactionId);
        }
    
    }

    function executeTransaction(uint _transactionId) public payable{
        require(_transactionId<transactions.length,"Invalid transaction id");
        require(!transactions[_transactionId].executed,"Transaction is already executed");
        //transactions[_transactionId].executed= true;
        (bool success,)=transactions[_transactionId].to.call{value: transactions[_transactionId].value}("");
        require(success,"Transaction Execution failed");
        transactions[_transactionId].executed= true;
        emit TransactionExecuted(_transactionId);

    }

    function isTransactionConfirmed(uint _transactionId) internal view returns(bool){
       require(_transactionId<transactions.length,"Invalid transaction id");
       uint confirmationCount; //initially zero

       for(uint i = 0;i<owners.length;i++) {
        if(isConfirmed[_transactionId][owners[i]]){
            confirmationCount++;
        }
       }
       return confirmationCount>=numConfirmationsRequired;
    }
}