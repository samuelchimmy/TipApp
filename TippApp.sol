// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/utils/SafeERC20.sol";

contract TipJar is Ownable {
    using SafeERC20 for IERC20;

    struct User {
        bool exists;
        address walletAddress;
        uint256 tips;
    }

    mapping(address => User) public users;

    event Payment(address indexed sender, uint256 amount);
    event Withdraw(address indexed recipient, uint256 amount);
    event WithdrawERC20(
        address indexed recipient,
        address indexed token,
        uint256 amount
    );

    receive() external payable {
        emit Payment(msg.sender, msg.value);
    }

    function createAccount() external {
        require(!users[msg.sender].exists, "Account already exists");

        users[msg.sender] = User(true, msg.sender, 0);
    }

    function deposit() external payable {
        require(users[msg.sender].exists, "Account does not exist");

        users[msg.sender].tips += msg.value;
        emit Payment(msg.sender, msg.value);
    }

    function withdrawTips() external {
        require(users[msg.sender].exists, "Account does not exist");

        uint256 amount = users[msg.sender].tips;
        users[msg.sender].tips = 0;

        (bool sent, ) = (msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit Withdraw(msg.sender, amount);
    }

    function transferEth(address _to, uint256 _amount) external onlyOwner {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");

        emit Withdraw(_to, _amount);
    }

    function transferERC20(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
        emit WithdrawERC20(_to, _token, _amount);
    }
}