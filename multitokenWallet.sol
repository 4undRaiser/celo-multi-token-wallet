// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract MultiTokenWallet {
    uint256 private _maxIdleTime = 30 minutes;

    address private contractOwner;

    constructor() {
        contractOwner = msg.sender;
    }

    mapping(address => mapping(address => uint256)) private _balances;
    mapping(address => bool) private _supportedTokens;
    mapping(address => uint256) private _lastSeen;

    event Deposit(
        address indexed account,
        address indexed token,
        uint256 amount
    );
    event Withdrawal(
        address indexed account,
        address indexed token,
        uint256 amount
    );

    function deposit(address token, uint256 amount) external {
        require(_supportedTokens[token], "Unsupported token");
        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "Token transfer failed"
        );
        _balances[msg.sender][token] += amount;
        _lastSeen[msg.sender] = block.timestamp;
        emit Deposit(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) external {
        require(_balances[msg.sender][token] >= amount, "Insufficient balance");
        require(
            IERC20(token).transfer(msg.sender, amount),
            "Token transfer failed"
        );
        _balances[msg.sender][token] -= amount;
        _lastSeen[msg.sender] = block.timestamp;
        emit Withdrawal(msg.sender, token, amount);
    }

    function balanceOf(
        address account,
        address token
    ) external view returns (uint256) {
        return _balances[account][token];
    }

    function setSupportedToken(address token, bool isSupported) external {
        require(
            msg.sender == owner(),
            "Only owner can modify supported tokens"
        );
        _supportedTokens[token] = isSupported;
    }

    function setMaxIdleTime(uint256 idleTime) external {
        require(msg.sender == owner(), "Only owner can modify max idle time");
        _maxIdleTime = idleTime;
    }

    function owner() public view returns (address) {
        return (contractOwner);
    }
}
