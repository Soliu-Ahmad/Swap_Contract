// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {IERC20} from "./IERC20.sol";


contract SwapToken {

    IERC20 public celloToken;
    IERC20 public usdtToken;
    address owner;
    bool internal locked;
    uint256 internal constant ONE_USDT_TO_CELLO = 2000;

    enum Currency {NONE, CELLO, USDT }

    mapping (Currency => uint256)  contractBalances;

    constructor(IERC20 _celloTokenCAddr, IERC20 _usdtTokenCAddr){
        celloToken = _celloTokenCAddr;
        usdtToken = _usdtTokenCAddr;
        owner = msg.sender;
    }

    event SwapSuccessful(address indexed from, address indexed to, uint256 amount);
    event WithdrawSuccessful(address indexed owner, Currency indexed _currencyName, uint256 amount);


    modifier reentrancyGuard() {
        require(!locked, "Reentrancy not allowed");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can access");
        _;
    }


    function swapCelloToUsdt(address _from, uint256 _amount) external reentrancyGuard  {
        require(msg.sender != address(0), "Zero not allowed");
        require(_amount > 0 , "Cannot swap zero amount");

        uint256 standardAmount = _amount * 10**18;

        uint256 userBal = celloToken.balanceOf(msg.sender);

        require(userBal >= _amount, "Your balance is not enough");

        uint256 allowance = celloToken.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Token allowance too low");


        bool deducted = celloToken.transferFrom(_from, address(this), standardAmount);

        require(deducted, "Excution failed");

        contractBalances[Currency.CELLO] +=  standardAmount;


        uint256 convertedValue_ = Cello_Usdt_Rate(standardAmount, Currency.CELLO);

        bool swapped = usdtToken.transfer(msg.sender, convertedValue_);


        if (swapped) {

            contractBalances[Currency.USDT] +=  convertedValue_;

            emit SwapSuccessful(_from, address(this), standardAmount );
        }

    }




    function swapUsdtToCello(address _from, uint256 _amount) external reentrancyGuard {
    require(msg.sender != address(0), "Zero not allowed");
    require(_amount > 0, "Cannot swap zero amount");

    
    uint256 standardAmount = _amount * 10**6;

    uint256 userBal = usdtToken.balanceOf(msg.sender);
    require(userBal >= standardAmount, "Your balance is not enough");

    uint256 allowance = usdtToken.allowance(msg.sender, address(this));
    require(allowance >= standardAmount, "Token allowance too low");

    bool deducted = usdtToken.transferFrom(_from, address(this), standardAmount);
    require(deducted, "Execution failed");

    contractBalances[Currency.USDT] += standardAmount;

    uint256 convertedValue_ = Cello_Usdt_Rate(standardAmount, Currency.USDT);
    bool swapped = celloToken.transfer(msg.sender, convertedValue_);

    if (swapped) {
        contractBalances[Currency.CELLO] += convertedValue_;
        emit SwapSuccessful(_from, address(this), standardAmount);
    }
}



        function getContractBalance() external view onlyOwner returns (uint256 contractUsdtbal_, uint256 contractNairabal_) {
        contractUsdtbal_ = usdtToken.balanceOf(address(this));
        contractNairabal_ = celloToken.balanceOf(address(this));
    }
    

 function Cello_Usdt_Rate (uint256 _amount, Currency _currency) internal pure returns (uint256 convertedValue_) {
        if(_currency == Currency.USDT) {
            convertedValue_ = _amount * ONE_USDT_TO_CELLO;  
        } else if(_currency == Currency.CELLO) {
            convertedValue_ = _amount  / ONE_USDT_TO_CELLO ;
        } else {
            revert("Unsupported currency");
        }
        return convertedValue_;
    }
}