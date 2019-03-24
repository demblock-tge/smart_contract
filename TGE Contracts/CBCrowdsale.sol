pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/WhitelistCrowdsale.sol";

contract CBCrowdsale is Ownable, Crowdsale, CappedCrowdsale, MintedCrowdsale, TimedCrowdsale, WhitelistCrowdsale {
    using SafeMath for uint256;
    // --------------------------------- Events
    event CrowdsaleFinalized(bool succeeded);

    // --------------------------------- Contract variables
    // Crowdsale data
    uint256 private _minInvest;
    uint private _salePercentage;

    /// Finalization data
    uint256 private _releaseTime;
    bool private _finalized;

    // --------------------------------- Ctor
    constructor(
      uint256 rate,
      address payable wallet,
      ERC20 token,
      uint256 cap,
      uint256 minInvest,
      uint salePercentage,
      uint256 openingTime,
      uint256 closingTime,
      uint256 releaseTime
    )
      Crowdsale(rate, wallet, token)
      CappedCrowdsale(cap)
      TimedCrowdsale(openingTime, closingTime)
      public
    {
        require(salePercentage <= 100, "Invalid avaliability amount");
        require(minInvest < cap, "Invalid investor min cap");
        require(releaseTime >= closingTime, "Release time must be after closing");

        _salePercentage = salePercentage;
        _releaseTime = releaseTime;
        _finalized = false;
        _minInvest = minInvest;
    }

    // --------------------------------------------------------
    // --------------------------------- Attributes
    // --------------------------------------------------------
    /**
        @dev Returns the percentage amount avaliable for crowdsale.
     */
    function getSalePercentage()
        public view returns (uint)
    {
        return _salePercentage;
    }

    /**
     * @return true if the crowdsale is finalized, false otherwise.
     */
    function finalized() 
      public view returns (bool) {
        return _finalized;
    }

    /**
     * @return checks if tokens can be released to owner.
     */
    function isReleasable() 
      public view returns (bool) {
        return block.timestamp >= _releaseTime;
    }

    /**
     * @return returns release time.
     */
    function releaseTime() 
      public view returns (uint256) {
        return _releaseTime;
    }

    /**
     * @return returns min cap.
     */
    function getMinimumCap() 
      public view returns (uint256) {
        return _minInvest;
    }

    /**
     * @return returns avaliable amount.
     */
    function getSaleAmount() 
      public view returns (uint256) {
        return cap().div(100).mul(_salePercentage);
    }

    /**
     * @return returns avaliable amount.
     */
    function getOwnerAmount() 
      public view returns (uint256) {
        return cap().div(100).mul(uint(100).sub(_salePercentage));
    }

    // --------------------------------------------------------
    // --------------------------------- Methods
    // --------------------------------------------------------
    /**
     * @dev Perform finalization when called finalization 
     */
    function finalize() public onlyOwner {
        require(!_finalized, "Already finalized");
        require(isReleasable(), "Cannot release tokens yet");

        _finalized = true;

        ERC20Mintable _mToken = ERC20Mintable(address(token()));
        _mToken.mint(wallet(),  getOwnerAmount().mul(rate()));

        emit CrowdsaleFinalized(true);
    }
    
    /**
     * @dev Add multiple accounts to whitelist
     */
    function addManyToWhitelist(address[] memory accounts) 
        public 
        onlyWhitelistAdmin
    {
        for (uint i = 0; i < accounts.length; i++) {
            addWhitelisted(accounts[i]);
        }
    }

    // --------------------------------------------------------
    // --------------------------------- Overrides
    // --------------------------------------------------------
    /**
    * @dev Extend parent behavior requiring purchase to respect investor min/max funding cap.
    * @param _beneficiary Token purchaser
    * @param _weiAmount Amount of wei contributed
    */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
      internal
      view
      onlyWhileOpen
    {
        require(isWhitelisted(_beneficiary), "Not whitelisted");
        require(_beneficiary != address(0), "Reciever addres not specified");
        require(_weiAmount >= _minInvest, "Too small donation");
        require(weiRaised().add(_weiAmount) <= getSaleAmount(), "Amount greater than avaliable");
    }
}