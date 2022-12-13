// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "../library/IERC20.sol";

contract ERC20 is IERC20 {
    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply; // 代币总供给

    string public name; // 名称
    string public symbol; // 代号

    uint8 public decimals = 18; // 小数位数


    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    function transfer(address recipient, uint amount) external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom (
        address sender,
        address recipient,
        uint amount
    ) external override returns (bool) {
        allowance[sender][msg.sender] += amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}


contract Faucet {

    uint256 public amountAllowed = 100; // 每次100个
    address public tokenContract; // token合约地址
    mapping(address => bool) public requestedAddress; // 记录领取地址

    event SendToken(address indexed Receiver, uint256 indexed amount);

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
    }

    function requestTokens() external {
        require(requestedAddress[msg.sender] == false, "Can't Request Multiple Times!");
        IERC20 token = IERC20(tokenContract); // 创建IERC20合约对象
        require(token.balanceOf(address(this)) >= amountAllowed, "faucet Empty!");

        token.transfer(msg.sender, amountAllowed); // 发生token
        requestedAddress[msg.sender] = true; // 记录地址

        emit SendToken(msg.sender, amountAllowed); // 释放SendToken事件
    }
}

contract Airdrop {

    function getSum(uint256[] calldata _arr) public pure returns(uint sum) {
        for(uint i = 0; i < _arr.length; i++) {
            sum = sum + _arr[i];
        }
    }

    /// @notice 向多个地址转账ERC20代币需要提前授权
    ///
    /// @param _token 转账的ERC20代币地址
    /// @param _addresses 接收空投的用户地址数组
    /// @param _amounts 代币数量数组
    function multiTransferToken(
        address _token,
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) external {
        // 检查 _addresses 和 _amounts数组的长度相等
        require(_addresses.length == _amounts.length, "Lengths of Addreses and Amounts Not Equal");
        IERC20 token = IERC20(_token); //声明IERC合约变量
        uint _amountSum = getSum(_amounts); //计算空投代币总量
        // 检查 授权代币数量 >= 空投代币总量
        require(token.allowance(msg.sender, address(this)) >= _amountSum, "Need Approve ERC20 token");

        // for循环 利用transferFrom函数发送空投
        for (uint8 i; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _amounts[i]);
        }
    }

    function multiTransferETH(
        address payable[] calldata _addresses,
        uint256[] calldata _amounts
    ) public payable {
        // 检查：_addresses和_amounts数组的长度相等
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
        uint _amountSum = getSum(_amounts); // 计算空投ETH总量
        // 检查转入ETH等于空投总量
        require(msg.value == _amountSum, "Transfer amount error");
        // for 循环 利用transfer函数发送ETH
        for (uint256 i = 0; i < _addresses.length; i++) {
            _addresses[i].transfer(_amounts[i]);
        }
    }
}