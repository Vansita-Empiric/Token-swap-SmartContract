// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "referral/token.sol";
import "hardhat/console.sol";

contract UserContract {

// 0x0000000000000000000000000000000000000000

    struct User {
        bytes4 userId;
        address userAddress;            
        string username;
        address tokenAddress;
        address receivedReferralCodeFrom;
        bytes4 referralCode;
        bool isRegistered;
    }

    struct RequestList {
        bytes4 reqId;
        address swapAddressFrom;
        address swapAddressTo;
        uint amount;
    }

    mapping(address => User) public users;
    mapping(string => bool) isNameUnavailable;
    mapping (bytes4 => RequestList) public requests;
    mapping (bytes4 => bool) isRequestApproved;
    mapping (bytes4 => bool) isRequestRejected;

    RequestList[] reqestArr;

    address a1 = address(this);

    function registerUser(string memory _username, address _receivedReferralCodeFrom, string memory _tokenName, string memory _tokenSymbol, uint _initialSupply) public {
        require(!users[msg.sender].isRegistered, "You have already registered with this account");
        require(!isNameUnavailable[_username], "Username not available");

        bytes4 uid = bytes4(keccak256(abi.encodePacked(block.timestamp)));
        bytes4 refCode = bytes4(keccak256(abi.encodePacked(block.timestamp, _username)));

        Token t1 = new Token(_tokenName, _tokenSymbol, _initialSupply);
       
        if(_receivedReferralCodeFrom != address(0)) {
            require(users[_receivedReferralCodeFrom].isRegistered, "Invalid referrer");
            
            Token t2 = Token(users[_receivedReferralCodeFrom].tokenAddress);
            t2.mint(msg.sender, 20);

            t1.mint(_receivedReferralCodeFrom, 20);
        }

        User memory userInstance = User(uid, msg.sender, _username, address(t1), _receivedReferralCodeFrom, refCode, true);
        users[msg.sender] = userInstance;
        
        isNameUnavailable[_username] = true;
    }

    function contractAdd() view external returns (address) {
        return a1;
    }
    
    function swapTokens(address _swapTo, uint _amount) internal {
        Token t3 = Token(users[msg.sender].tokenAddress);
        t3.transferFrom(msg.sender, _swapTo, _amount);

        Token t4 = Token(users[_swapTo].tokenAddress);
        t4.transferFrom(_swapTo, msg.sender, _amount);
    }

    function requestSwap(address _swapTo, uint _amount) public {
        require(users[msg.sender].isRegistered, "You have to register first");
        require(users[_swapTo].isRegistered, "Invalid swap user");

        Token t1 = Token(users[msg.sender].tokenAddress);
        require(t1.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        require(_swapTo != msg.sender, "You can not swap with own account");

        console.log("users[msg.sender].tokenAddress: ", users[msg.sender].tokenAddress);
        console.log("users[_swapTo].tokenAddress: ", users[_swapTo].tokenAddress);
        console.log("Address: ", address(this));

        bytes4 rid = bytes4(keccak256(abi.encodePacked(block.timestamp)));
        RequestList memory requestInstance = RequestList(rid, msg.sender, _swapTo, _amount);
        requests[rid] = requestInstance;
        reqestArr.push(requestInstance);
    }

    function getAllRequests() public view returns (RequestList[] memory) {
        return reqestArr;
    }

    function approveSwap(bytes4 _reqId) public {
        require(!isRequestApproved[_reqId], "Swapping is already done");
        require(!isRequestRejected[_reqId], "Swapping rejected");
        require(msg.sender == requests[_reqId].swapAddressTo, "You can not approve swap");
        
        swapTokens(requests[_reqId].swapAddressFrom, requests[_reqId].amount);
        isRequestApproved[_reqId] = true;
    }

    function rejectSwap(bytes4 _reqId) public {
        require(!isRequestApproved[_reqId], "Swapping is already done");
        require(!isRequestRejected[_reqId], "Swapping rejected");
        require(msg.sender == requests[_reqId].swapAddressTo, "You can not reject swap");

        isRequestRejected[_reqId] = true;
    }
}