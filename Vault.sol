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

contract Vault {
    IERC20 public immutable token;

    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function _mint(address _to, uint _shares) private {
        totalSupply += _shares;
        balanceOf[_to] += _shares;
    }

    function _burn(address _from, uint _shares) private {
        totalSupply -= _shares;
        balanceOf[_from] -= _shares;
    }

    function deposit(uint _amount) external {
        uint shares;
        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply) / token.balanceOf(address(this));
        }

        _mint(msg.sender, shares);
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        emit Deposit(msg.sender, msg.sender, _amount, shares);
    }

    function withdraw(uint _shares) external {
        uint amount = (_shares * token.balanceOf(address(this))) / totalSupply;
        _burn(msg.sender, _shares);
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit Withdraw(msg.sender, msg.sender, msg.sender, amount, _shares);
    }

    function getPricePerShare() public view returns (uint) {
        if (totalSupply == 0) {
            return 1e18;
        }
        return (token.balanceOf(address(this)) * 1e18) / totalSupply;
    }

    function depositFor(address _for, uint _amount) external returns (uint shares) {
        shares = (_amount * totalSupply) / token.balanceOf(address(this));
        if (shares == 0) revert("Cannot mint 0 shares");
        _mint(_for, shares);
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        emit Deposit(msg.sender, _for, _amount, shares);
    }

    function previewWithdraw(uint _shares) public view returns (uint) {
        return (_shares * token.balanceOf(address(this))) / totalSupply;
    }

    function sweep(address _token) external {
        require(_token != address(token), "Cannot sweep vault token");
        IERC20 otherToken = IERC20(_token);
        uint balance = otherToken.balanceOf(address(this));
        require(otherToken.transfer(msg.sender, balance), "Sweep transfer failed");
    }

    event Deposit(address indexed caller, address indexed owner, uint assets, uint shares);
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint assets, uint shares);
}
