pragma solidity ^0.4.18;

import './OBTToken.sol';
import './SafeMath.sol';
import './Ownable.sol';

/**
 * @title OBTCrowdsale
 * @dev OBTCrowdsale is a completed contract for managing a token crowdsale.
 * OBTCrowdsale have a start and end timestamps, where investors can make
 * token purchases and the OBTCrowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract OBTCrowdsale is Ownable{
    using SafeMath for uint256;

    // The token being sold
    OBTToken public token;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // address where funds are collected
    address public wallet;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;

    // amount of hard cap
    uint256 public cap;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event TokenContractUpdated(bool state);

    event WalletAddressUpdated(bool state);

    function OBTCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _token, uint256 _cap) public {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));
        require(_cap > 0);

        token = OBTToken(_token);
        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
        cap = _cap;
    }


    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool withinCap = weiRaised.add(msg.value) <= cap;

        return withinPeriod && nonZeroPurchase && withinCap;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        bool capReached = weiRaised >= cap;
        bool timeEnded = now > endTime;

        return timeEnded || capReached;
    }

    // update token contract
    function updateOBTToken(address _tokenAddress) onlyOwner{
        require(_tokenAddress != address(0));
        token = OBTToken(_tokenAddress);

        TokenContractUpdated(true);
    }

    // update wallet address
    function updateWalletAddress(address _newWallet) onlyOwner {
        require(_newWallet != address(0));
        wallet = _newWallet;

        WalletAddressUpdated(true);
    }

}
