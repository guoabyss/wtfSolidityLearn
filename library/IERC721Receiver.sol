// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}