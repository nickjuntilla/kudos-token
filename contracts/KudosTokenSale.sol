pragma solidity ^0.4.15;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./KudosToken.sol";

/**
 * @title KudosTokenSale
 * @author Ben Johnson
 *
 * @dev KudosTokenSale is a token crowdsale contract
 * @dev Based on KinTokenSale contract: https://github.com/kikinteractive/kin-token
 * @dev Based on WildCryptoICO's Crowdsale contract: https://github.com/WildCryptoICO/Wild-Crypto-Token
 */
contract KudosTokenSale is Ownable, TokenHolder {
   using SafeMath for uint256;

   KudosToken public kudosToken;

   uint256 public startTime;
   uint256 public constant numberOfDays = 30;
   uint256 public constant ethPriceInDollars = 287;
   address public wallet;

   uint256 public constant tokenUnit = 10 ** 18;
   uint256 public constant oneMillion = 10 ** 6;
   uint256 public constant oneBillion = 10 ** 9;
   uint256 public constant amountOfTokensForSale = 4 * oneBillion * tokenUnit;

   uint256 public constant goalInDollars = 30 * oneMillion;
   uint256 public constant kutoasPerDollar = amountOfTokensForSale/goalInDollars;

   uint256 public constant weiPerDollar = uint256(1 ether) / ethPriceInDollars;
   uint256 public constant kutoasPerWei = kutoasPerDollar / weiPerDollar;

   function KudosTokenSale(address _wallet, uint256 _startTime, address _tokenContractAddress) {

      require(_wallet != address(0));
      require(_startTime >= now);
      require(_tokenContractAddress != address(0));

      wallet = _wallet;
      startTime = _startTime;
      kudosToken = KudosToken(_tokenContractAddress);
   }

   function tokensAvailable() constant returns (uint256) {
      return kudosToken.balanceOf(this);
   }

   modifier whenTokenSaleIsActive() {
      require(isActive());
      _;
   }

   function isActive() constant returns (bool) {
      return (
         isAfterStartTime() &&
         isBeforeEndTime() &&
         tokensAreAvailable()
      );
   }

   function isAfterStartTime() constant returns (bool) {
      return now >= startTime;
   }

   function isBeforeEndTime() constant returns (bool) {
      return now <= startTime.add(numberOfDays * 1 days);
   }

   function tokensAreAvailable() constant returns (bool) {
      return tokensAvailable() > 0;
   }

   function () payable {
      issueTokens();
   }

   event IssueTokens(address indexed to, uint256 ethValue, uint256 amountOfTokens);

   function issueTokens() payable whenTokenSaleIsActive {

      require(msg.value > 0);

      uint256 weiLeftInSale = tokensAvailable().div(kutoasPerWei);
      uint256 weiAmount = SafeMath.min256(msg.value, weiLeftInSale);

      // transfer wei to wallet
      wallet.transfer(weiAmount);

      // issue tokens and send to buyer
      uint256 tokensToIssue = getNumberOfTokensToIssue(weiAmount);
      assert(kudosToken.transfer(msg.sender, tokensToIssue));
      IssueTokens(msg.sender, msg.value, tokensToIssue);

      // partial refund if full participation not possible due to cap being reached.
      uint256 refund = msg.value.sub(weiAmount);
      if (refund > 0) {
          msg.sender.transfer(refund);
      }
   }

   function getNumberOfTokensToIssue(uint256 weiAmount) internal constant returns (uint256) {

      uint256 numberOfTokensToIssue = weiAmount.mul(kutoasPerWei);

      // if purchase would cause less kutoasPerWei tokens left available that nobody could ever buy them,
      // then gift them to the last buyer.
      if (tokensAvailable().sub(numberOfTokensToIssue) < kutoasPerWei) {
         numberOfTokensToIssue = tokensAvailable();
      }

      return numberOfTokensToIssue;
   }

   function endTokenSale() onlyOwner {

      // transfer unsold tokens back to owner
      uint256 balance = kudosToken.balanceOf(this);
      require(balance > 0);
      assert(kudosToken.transfer(owner, balance));
   }
}
