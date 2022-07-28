// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract WQWallet is Ownable {
       
    mapping(address => mapping (address => uint256)) public ERC20Holders;
    mapping(address => mapping (address => uint256[])) public ERC721Holders;
    mapping(address => mapping (address => mapping(uint256 => uint256))) public ERC1155Holders;
    mapping(uint256 => address) public nftcontractlist;

    constructor(){}
    
    modifier checkERC721Holder(address _tokenContract, uint256[] calldata _tokenIds) {
        bool checkHolder = false;
        uint256 len = _tokenIds.length;
        for (uint256 j; j < len; ++j) {
            for(uint256 i = 0; i < ERC721Holders[msg.sender][_tokenContract].length; i++){
                if(ERC721Holders[msg.sender][_tokenContract][i] == _tokenIds[j]){
                    checkHolder = true;
                    break;
                }
            }
            assert(checkHolder);
            checkHolder = false;
        }
        _;
    }

    function removeItemfromERC721Holders(address owner, address _tokenContract, uint256 _tokenId) private {
         for(uint256 i = 0; i < ERC721Holders[owner][_tokenContract].length; i++) {
            uint256 arrayLength = ERC721Holders[owner][_tokenContract].length;
            if(ERC721Holders[owner][_tokenContract][i] == _tokenId){
                ERC721Holders[owner][_tokenContract][i] = ERC721Holders[owner][_tokenContract][arrayLength - 1];
                ERC721Holders[owner][_tokenContract].pop();
                break;
            }
        }
    }

    function DepositERC20(address _tokenContract, uint256 _amount, address _walletAddress) external{
        require(IERC20(_tokenContract).balanceOf(msg.sender) > _amount, "ERROR:Low Balance");
        IERC20(_tokenContract).transferFrom(msg.sender, address(this), _amount);
        ERC20Holders[_walletAddress][_tokenContract] += _amount;
    }

    function DepositERC721(address _tokenContract, uint256[] calldata _tokenIds, address _walletAddress) external{
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            require(IERC721(_tokenContract).ownerOf(_tokenIds[i]) == msg.sender, "ERROR:Your are not owner of this token");
            IERC721(_tokenContract).safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            ERC721Holders[_walletAddress][_tokenContract].push(_tokenIds[i]);
        }
    }

    function DepositERC1155(address _tokenContract, uint256 _amount, uint256 _tokenId, address _walletAddress) external{
        require(IERC1155(_tokenContract).balanceOf(msg.sender, _tokenId) > _amount, "ERROR:Low Balance");
        IERC1155(_tokenContract).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        ERC1155Holders[_walletAddress][_tokenContract][_tokenId] += _amount;
        this.arrayERC1155tokenID(_tokenContract, _walletAddress);
    }

    function TransferERC20(address _tokenContract, address _to, uint256 _amount) external {
        require(ERC20Holders[msg.sender][_tokenContract] >= _amount, "ERROR: Low Balance");
        IERC20(_tokenContract).transfer(_to, _amount);
        ERC20Holders[msg.sender][_tokenContract] -= _amount;
    }

    function TransferERC721(address _tokenContract, address _to, uint256[] calldata _tokenIds) external checkERC721Holder(_tokenContract, _tokenIds) {
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            IERC721(_tokenContract).transferFrom(address(this), _to, _tokenIds[i]);
            removeItemfromERC721Holders(msg.sender, _tokenContract, _tokenIds[i]);
        }
    }

    function TransferERC1155(address _tokenContract, address _walletAddress, address _to, uint256 _amount, uint256 _tokenId) external {
        require(IERC1155(_tokenContract).balanceOf(msg.sender, _tokenId) > _amount, "ERROR:Low Balance");
        IERC1155(_tokenContract).safeTransferFrom(address(this), _to, _tokenId, _amount, "");
        ERC1155Holders[msg.sender][_tokenContract][_tokenId] -= _amount;
        this.arrayERC1155tokenID(_tokenContract, _walletAddress);
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
        require(ERC20Holders[msg.sender][_tokenContract] >= _amount, "ERROR: Low Balance");
        IERC20(_tokenContract).transfer(msg.sender, _amount);
        ERC20Holders[msg.sender][_tokenContract] -= _amount;
    }
    
    function WithdrawERC721(address _tokenContract, uint256[] calldata _tokenIds) external checkERC721Holder(_tokenContract, _tokenIds) {
        uint256 len = _tokenIds.length;
        for (uint256 i = 0; i < len; ++i) {
            IERC721(_tokenContract).transferFrom(address(this), msg.sender, _tokenIds[i]);
            removeItemfromERC721Holders(msg.sender, _tokenContract, _tokenIds[i]);
        }
    }

    function WithdrawERC1155(address _tokenContract, address _walletAddress, uint256 _amount, uint256 _tokenId) external {
        require(IERC1155(_tokenContract).balanceOf(msg.sender, _tokenId) > _amount, "ERROR:Low Balance");
        IERC1155(_tokenContract).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
        ERC1155Holders[msg.sender][_tokenContract][_tokenId] -= _amount;
        this.arrayERC1155tokenID(_tokenContract, _walletAddress);
    }


    function ERC20TokenBalance(address _tokenContract) public view returns(uint256) {
        uint256 balance = ERC20Holders[msg.sender][_tokenContract];
        return balance;
    }

    function ERC721TokenOwnerByIndex(address _tokenContract, uint256 index) public view returns(uint256) {
        require(index < ERC721Holders[msg.sender][_tokenContract].length, "Owner index out of bounds");
        return ERC721Holders[msg.sender][_tokenContract][index];
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

    function setNewNFTContract(address _newnftcontact) public onlyAdmin {
        uint256 arrayLength = nftcontractlist.length;
        nftcontractlist[arrayLength + 1] = _newnftcontact;
    }

    function ERC1155TokenBalance(address _wallet) public onlyAdmin {
        uint256[] _result;
        unint256 resindex = 0;
        uint256 len = nftcontractlist.length;
        for (uint256 i = 0; i < len; ++i) {
            address _nftaddress = nftcontractlist[i];
            _result[resindex] = ERC1155Holders[_wallet][_nftaddress];
            resindex += 1;
        }
        return _result;
    }

    function arrayERC1155tokenID(address _tokenContract, address _walletAddress) external returns(uint256[] memory) {
        uint256[] tokenIDarray =  ERC1155Holders[_walletAddress][_tokenContract];
        return tokenIDarray;
    }
    
}