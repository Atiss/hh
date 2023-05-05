// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20R is IERC20 {
    function mint(address to, uint256 amount) external;
}

contract Staking is Ownable {
    IERC20R public usdtErc20;
    IERC20R public theRomaToken;

    struct Stake {
        uint256 amount;
        uint256 time;
    }

    mapping(address => Stake) public stakes;
    mapping(address => uint256) public stakingTime;
    address[] public whitelist;

    uint256 public constant PERIOD = 2 minutes;
    uint256 public constant PERCENT = 10;
    uint256 public constant AIR_DROP = 200;

    constructor(address _usdtErc20, address _theRomaToken) {
        usdtErc20 = IERC20R(_usdtErc20);
        theRomaToken = IERC20R(_theRomaToken);
    }

    function buyTokens(uint256 _amount) external {
        require(stakes[msg.sender].amount == 0, "You already have a stake");
        require(usdtErc20.balanceOf(msg.sender) >= _amount, "Not enough tokens");
        usdtErc20.transferFrom(msg.sender, address(this), _amount);
        theRomaToken.mint(address(this), _amount);
        stake(_amount);
    }

    function stake(uint256 _amount) private {
        stakes[msg.sender].amount += _amount;
        stakes[msg.sender].time = block.timestamp;
    }

    function withdraw() external {
        require(block.timestamp - stakes[msg.sender].time >= PERIOD, "You can't unstake yet");
        require(stakes[msg.sender].amount > 0, "You don't have a stake");
        uint256 _amount = stakes[msg.sender].amount;
        stakes[msg.sender].amount = 0;
        stakes[msg.sender].time = 0;
        theRomaToken.transferFrom(address(this), msg.sender, _amount);
    }

    function claim() external {
        require(stakes[msg.sender].amount > 0, "You don't have a stake");
        uint256 reward = stakes[msg.sender].amount * PERCENT * (block.timestamp - stakes[msg.sender].time) / PERIOD;
        stakes[msg.sender].time = block.timestamp;
        theRomaToken.mint(msg.sender, reward);
    }

    function addWhitelist(address _address) external onlyOwner {
        whitelist.push(_address);
    }

    function airDrop() external onlyOwner{
        for (uint256 i = 0; i < whitelist.length; i++) {
            address _address = whitelist[i];
            theRomaToken.mint(_address, AIR_DROP);
        }
    }

}
