// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract WQWallet is Ownable {
       
    mapping(address => mapping (address => uint256)) public ERC20Holders;
    mapping(address => mapping (address => uint256)) public ERC721Holders;
    mapping(address => mapping (address => mapping(uint256 => uint256))) public ERC1155Holders;
    
    constructor(){}
    
    function DepositERC20(address _tokenContract, uint256 _amount) external{
        require(IERC20(_tokenContract).balanceOf(msg.sender) > _amount, "ERROR:Low Balance");
        IERC20(_tokenContract).transferFrom(msg.sender, address(this), _amount);
        ERC20Holders[msg.sender][_tokenContract] += _amount;
    }
    function DepositERC721(address _tokenContract, uint256 _tokenId) external{
        require(IERC721(_tokenContract).ownerOf(_tokenId) == msg.sender, "ERROR:Your are not owner of this token");
        IERC721(_tokenContract).safeTransferFrom(msg.sender, address(this), _tokenId);
        ERC721Holders[msg.sender][_tokenContract] = _tokenId;
    }

    function DepositERC1155(address _tokenContract, uint256 _amount, uint256 _tokenId) external{
        require(IERC1155(_tokenContract).balanceOf(msg.sender, _tokenId) > _amount, "ERROR:Low Balance");
        IERC1155(_tokenContract).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        ERC1155Holders[msg.sender][_tokenContract][_tokenId] += _amount;
    }

    function TransferERC20(address _tokenContract, address _to, uint256 _amount) external {
        require(ERC20Holders[msg.sender][_tokenContract] > _amount, "ERROR: Low Balance");
        IERC20(_tokenContract).transfer(_to, _amount);
        ERC20Holders[msg.sender][_tokenContract] -= _amount;
    }

    function TransferERC1155(address _tokenContract, address _to, uint256 _amount, uint256 _tokenId) external {
        require(IERC1155(_tokenContract).balanceOf(msg.sender, _tokenId) > _amount, "ERROR:Low Balance");
        IERC1155(_tokenContract).safeTransferFrom(address(this), _to, _tokenId, _amount, "");
        ERC1155Holders[msg.sender][_tokenContract][_tokenId] -= _amount;
    }

    function TransferBatchERC1155(address _tokenContract, address _to, uint256[] memory _amounts, uint256[] memory _tokenIds) external {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(IERC1155(_tokenContract).balanceOf(msg.sender, _tokenIds[i]) > _amounts[i], "ERROR:Low Balance");
        }
        IERC1155(_tokenContract).safeBatchTransferFrom(address(this), _to, _tokenIds, _amounts, "");
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            ERC1155Holders[msg.sender][_tokenContract][_tokenIds[i]] -= _amounts[i];
        }
    }

    function WithdrawERC20(address _tokenContract, uint256 _amount) external {
        require(ERC20Holders[msg.sender][_tokenContract] > _amount, "ERROR: Low Balance");
        IERC20(_tokenContract).transfer(msg.sender, _amount);
        ERC20Holders[msg.sender][_tokenContract] -= _amount;
    }

    function WithdrawERC1155(address _tokenContract, uint256 _amount, uint256 _tokenId) external {
        require(IERC1155(_tokenContract).balanceOf(msg.sender, _tokenId) > _amount, "ERROR:Low Balance");
        IERC1155(_tokenContract).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
        ERC1155Holders[msg.sender][_tokenContract][_tokenId] -= _amount;
    }


    function ERC20TokenBalance(address _tokenContract) public view returns(uint256) {
        uint256 balance = ERC20Holders[msg.sender][_tokenContract];
        return balance;
    }
    
    function ERC1155TokenBalance(address _tokenContract, uint256 _tokenId) public view returns(uint256) {
        uint256 balance = ERC1155Holders[msg.sender][_tokenContract][_tokenId];
        return balance;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}