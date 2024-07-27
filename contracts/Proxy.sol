
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Proxy{
    /**
     * @notice The storage slot that holds the address of the implementation.
     *         bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
     */
    bytes32 internal constant IMPLEMETATION_KEY=0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    /**
     * @notice The storage slot that holds the address of the owner.
     *         bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
     */
    bytes32 internal constant OWNER_KEY =  0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    //An event that is emitted each time the implementation is changed.
    event Upgraded(address indexed _implementation);

    //An event that is emitted each time the owner is upgraded.
    event AdminChanged(address _previousAdmin , address _newAdmin);

    //A modifier that reverts if not called by the owner or by address(0) .
    modifier ProxyCallIfNotAdmin(){
        if(msg.sender==_getAdmin()||msg.sender==address(0)){
            _;
        }
        else {
            _doProxyCall();
        }
    }

    //Sets the initial owner during contract deployment
    constructor(){
        _setOwner(msg.sender);
    }

    receive() external payable { 
        _doProxyCall();
    }

    fallback() external payable {
        _doProxyCall();
    }

    //Sets the implementation to the new implemented contract address .
    function upgradeTo(address _implementation) public virtual ProxyCallIfNotAdmin{
        _setImplementation(_implementation);
    }

    //Set the implementation and call a function in a single transaction.
    function upgradeToAndCall(address _implementation, bytes calldata _data)
    public 
    payable 
    virtual 
    ProxyCallIfNotAdmin
    returns (bytes memory){
        _setImplementation(_implementation);
        (bool success , bytes memory returndata) = _implementation.delegatecall(_data);
        require(success,"Proxy : delegatecall to new implementation failed");
        return returndata;
    }
    
    //Sets the owner of this contract.
    function _setOwner(address _owner) internal {
        assembly {
            sstore(OWNER_KEY, _owner)
        }
    }

    //notice Changes the owner of the proxy contract. Only callable by the owner.
    function changeAdmin(address _admin) public virtual ProxyCallIfNotAdmin{
        _changeAdmin(_admin);
    }
    //Changes the owner of the proxy contract.internally called by above function.
    function _changeAdmin(address _admin) internal{
        address previous = _getAdmin();
        assembly{
            sstore(OWNER_KEY,_admin)
        }
        emit AdminChanged(previous,_admin);
    }

    //Gets the owner of the proxy contract.
    function Admin()public virtual ProxyCallIfNotAdmin returns(address ){
        return _getAdmin();
    }
    //Gets the owner of the proxy contract.
    function _getAdmin() public view returns(address){
        address owner;
        assembly{
            owner :=sload(OWNER_KEY)
        }
        return owner;
    }

    //Queries the implementation address.
    function implememtation() public virtual ProxyCallIfNotAdmin returns(address){
       return _getImplementation();
    }
    //returns  implementation address.
    function _getImplementation()public view returns(address){
        address impl;
        assembly{
            impl:=sload(IMPLEMETATION_KEY)
        }
        return impl;
    }

    //Sets the implementation address.
    function _setImplementation(address _implementation) internal{
        assembly{
            sstore(IMPLEMETATION_KEY,_implementation)
        }

        emit Upgraded(_implementation);
    }

    //performs the proxy call via a delegatecall
    function _doProxyCall()internal{
        address impl = _getImplementation();
        require(impl!=address(0),"Implementation is not initialized");

        assembly{

            // Copy calldata into memory at 0x0....calldatasize.
            calldatacopy(0,0,calldatasize())

            // Perform the delegatecall, make sure to pass all available gas.
            let success:= delegatecall(gas() ,impl , 0 , calldatasize(),0,0 )

            //// Copy returndata into memory at 0x0....returndatasize.
            returndatacopy(0,0,returndatasize())

            switch success 
            // Success == 0 means a revert. We'll revert too and pass the data up.
            case 0{
                revert(0,returndatasize())
            }
            default {
                return(0,returndatasize())
            }
            // Otherwise we'll just return and pass the data up.

        }
    }
}