// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Revenue is Ownable {
    
    using SafeMath for uint256;

    uint256[] public coefficients;
    uint256[] public burnings;
    address[] public wallets;
    
    IERC20 public WQT;
    IERC20 public WQC;

    constructor(IERC20 _WQT, IERC20 _WQC) {
        WQT = _WQT;
        WQC = _WQC;
    }

    modifier checkCoefficients (uint256 _cofficient){
        uint256 temp;
        for (uint8 i = 0; i < coefficients.length; i++) {
            temp += coefficients[i];
        }
        require(temp.add(_cofficient) <= 100, "Wrong value");
        _;
    }

    function addCoefficients(uint256 _cofficient) external checkCoefficients(_cofficient){
        require(_cofficient < 100, "each _cofficient must be less than 100");
        coefficients.push(_cofficient);
    }
    
    function addburnings(uint256 _burn) external {
        require(_burn < 100, "each _burn percentage must be less than 100");
        burnings.push(_burn);
    }

    function addWallets(address _address) external {
        wallets.push(_address);
    }

    function changeCoefficients(uint256 _index, uint256 _cofficient) external {
        coefficients[_index] = _cofficient;
    }

    function changeBurnings(uint256 _index, uint256 _burn) external {
        burnings[_index] = _burn;
    }

    function changeWallets(uint256 _index, address _address) external {
        wallets[_index] = _address;
    }

    function withdraw() external{
        require(coefficients.length == wallets.length, "Length must be same");
        uint256 WQT_balance  = WQT.balanceOf(address(this));
        uint256 WQC_balance  = WQC.balanceOf(address(this));
        for(uint8 i = 0; i < coefficients.length; i++) {
            WQT.transfer(wallets[i], WQT_balance.mul(coefficients[i]).div(100) - WQT_balance.mul(coefficients[i]).div(100).mul(burnings[i]).div(100));
            WQC.transfer(wallets[i], WQC_balance.mul(coefficients[i]).div(100) - WQC_balance.mul(coefficients[i]).div(100).mul(burnings[i]).div(100));
        }
    }
}