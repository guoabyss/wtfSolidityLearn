// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DutchAuction is Ownable, ERC721 {

    uint256 public constant COLLECTOIN_SIZE = 10000;  //NFT总量
    uint256 public constant AUCTION_START_PRICE = 1 ether; // 起拍价（最高价）
    uint256 public constant AUCTION_END_PRICE = 0.1 ether; // 结束价（最低价）
    uint256 public constant AUCTION_TIME = 10 minutes; // 拍卖时间 
    uint256 public constant AUCTION_DROP_INTERVAL = 1 minutes; // 价格衰减时间间隔
    uint256 public constant AUCTION_DROP_PER_STEP = (AUCTION_START_PRICE - AUCTION_END_PRICE) / (AUCTION_TIME / AUCTION_DROP_INTERVAL); // 每次价格衰减步长
    uint256 public auctionStartTime; // 拍卖开始时间戳
    string private _baseTokenURI; // metadata URI
    uint256[] private _allTokens; // 记录所有存在的tokenId


    constructor() ERC721("WTF Dutch Auction", "WTF Dutch Auction") {
        auctionStartTime = block.timestamp;
    }

    /**
    ERC721Enumerable中totalSupply函数的实现
    **/
    function totalSupply() public view virtual returns (uint256) {
        return _allTokens.length;
    }

    /**
     * Private函数，在_allTokens中添加一个新的token
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokens.push(tokenId);
    }

    // 设置开始拍卖时间 只有所有者可以调用
    function setAuctionStartTime(uint32 timestamp) external onlyOwner {
        auctionStartTime = timestamp;
    }

    // 获取实时拍卖价格
    function getAuctionPrice() public view returns(uint256) {
        if (block.timestamp < auctionStartTime) {
            return AUCTION_START_PRICE;
        }else if (block.timestamp - auctionStartTime >= AUCTION_TIME) {
            return AUCTION_END_PRICE;
        }else {
            uint256 steps = (block.timestamp - auctionStartTime) / AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }

    // 拍卖mint函数
    function auctionMint(uint256 quantity) external payable {
        uint256 _saleStartTime = uint256(auctionStartTime); // 建立loacl变量 减少gas花费
        require(_saleStartTime != 0 && block.timestamp >= _saleStartTime,
        "sale has not started yet"); // 检查是否设置起拍时间 拍卖是否开始

        require(totalSupply() + quantity <= COLLECTOIN_SIZE,
        "not enough remaining reserved for auction to support desired mint amount"); //检查是否超过NFT上限

        uint256 totalCost = getAuctionPrice() * quantity; // 计算mint成本
        require(msg.value >= totalCost, "Need to send more ETh."); // 检查用户是否支付足够的eth

        //mint nft
        for(uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            _mint(msg.sender, mintIndex);
            _addTokenToAllTokensEnumeration(mintIndex);
        }

        // 多余Eth退款
        if(msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    // 提款函数
    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}