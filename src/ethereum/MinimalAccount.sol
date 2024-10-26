//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
contract MinimalAccount is IAccount,Ownable{
    /*//////////////////////////////////////////////////////////////
                           Errors
  //////////////////////////////////////////////////////////////*/
  error MinimalAccount__NotFromEntryPoint();
  error MinimalAccount__NotOwnerOrEntryPoint();
  error MinimalAccount_callFailed();

    /*//////////////////////////////////////////////////////////////
                          STATE VARIABLES
  //////////////////////////////////////////////////////////////*/
  IEntryPoint private immutable i_entryPoint;

      /*//////////////////////////////////////////////////////////////
                           Modifier
  //////////////////////////////////////////////////////////////*/
  modifier requireFromEntryPoint(){

  if(msg.sender != address(i_entryPoint) ){
      revert MinimalAccount__NotOwnerOrEntryPoint();
    }
    _;
  }

  modifier requireFromEntryPointOrOwner(){

  if(msg.sender != address(i_entryPoint) && msg.sender != owner() ){
      revert MinimalAccount__NotOwnerOrEntryPoint();
    }
    _;
  }

  
  constructor(address entryPoint)Ownable(msg.sender){
    i_entryPoint = IEntryPoint(entryPoint);
  }

  

  /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function execute(address dest, uint256 value, bytes calldata func) external requireFromEntryPointOrOwner() returns (bool success, bytes memory ret){
    (success,ret) = dest.call{value : value, gas : type(uint256).max}(func);
    if(!success){
      revert MinimalAccount_callFailed();
    }
  }
    //A signature is valid if it's the minimalAccount owner
  function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds) external  returns (uint256 validationData) {
    validationData = _validateSignature(userOp,userOpHash);
    _payPrefund(missingAccountFunds);
  }
    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
  //////////////////////////////////////////////////////////////*/
  function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash) internal view returns(uint256 validationData) {
    bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
    address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
    if(signer!=owner()){
      return SIG_VALIDATION_FAILED;
    }
    else{
      return SIG_VALIDATION_SUCCESS;
    }
  }
  function _payPrefund(uint256 missingAccountFunds) internal{
    if(missingAccountFunds != 0){
      (bool success,) = payable(msg.sender).call{value : missingAccountFunds, gas: type(uint256).max}("");
      (success);
    }
  }

  receive() external payable{}
  /*//////////////////////////////////////////////////////////////
                           Getter
  //////////////////////////////////////////////////////////////*/

  function getEntryPoint() external view returns(address){
    return address(i_entryPoint);
  }
}