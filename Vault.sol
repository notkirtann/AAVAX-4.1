// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract SafeVault {
    IERC20 public immutable asset;

    uint public totalUnits;
    mapping(address => uint) public unitBalance;

    constructor(address _asset) {
        asset = IERC20(_asset);
    }

    function _addUnits(address _recipient, uint _units) private {
        totalUnits += _units;
        unitBalance[_recipient] += _units;
    }

    function _removeUnits(address _sender, uint _units) private {
        totalUnits -= _units;
        unitBalance[_sender] -= _units;
    }

    function addAsset(uint _amount) external {
        uint units;
        if (totalUnits == 0) {
            units = _amount;
        } else {
            units = (_amount * totalUnits) / asset.balanceOf(address(this));
        }

        _addUnits(msg.sender, units);
        require(asset.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        emit AssetAdded(msg.sender, msg.sender, _amount, units);
    }

    function removeAsset(uint _units) external {
        uint amount = (_units * asset.balanceOf(address(this))) / totalUnits;
        _removeUnits(msg.sender, _units);
        require(asset.transfer(msg.sender, amount), "Transfer failed");
        emit AssetRemoved(msg.sender, msg.sender, msg.sender, amount, _units);
    }

    function calculateUnitPrice() public view returns (uint) {
        if (totalUnits == 0) {
            return 1e18;
        }
        return (asset.balanceOf(address(this)) * 1e18) / totalUnits;
    }

    function addAssetFor(address _recipient, uint _amount) external returns (uint units) {
        units = (_amount * totalUnits) / asset.balanceOf(address(this));
        if (units == 0) revert("Cannot mint 0 units");
        _addUnits(_recipient, units);
        require(asset.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        emit AssetAdded(msg.sender, _recipient, _amount, units);
    }

    function estimateWithdrawal(uint _units) public view returns (uint) {
        return (_units * asset.balanceOf(address(this))) / totalUnits;
    }

    function clearAsset(address _token) external {
        require(_token != address(asset), "Cannot clear primary asset");
        IERC20 altToken = IERC20(_token);
        uint balance = altToken.balanceOf(address(this));
        require(altToken.transfer(msg.sender, balance), "Clear transfer failed");
    }

    event AssetAdded(address indexed caller, address indexed owner, uint amount, uint units);
    event AssetRemoved(address indexed caller, address indexed receiver, address indexed owner, uint amount, uint units);
}
