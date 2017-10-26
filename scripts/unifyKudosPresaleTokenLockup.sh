#!/bin/sh

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function unify() {
	grep -v "^[pragma|import]" $DIR/$1 >> KudosPresaleTokenLockupUnified.sol
}

echo "pragma solidity ^0.4.15;" > KudosPresaleTokenLockupUnified.sol

unify ../contracts/SafeMath.sol
unify ../contracts/ERC20Token.sol
unify ../contracts/StandardToken.sol
unify ../contracts/Ownable.sol
unify ../contracts/TokenHolder.sol
unify ../contracts/KudosToken.sol
unify ../contracts/KudosPresaleTokenLockup.sol
