// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakingBEET {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        bool active;
    }

    struct UnstakedToken {
        uint256 amount;
        uint256 unlockTime;
        bool withdrawn;
    }

    mapping(address => Stake) public stakes;
    mapping(address => UnstakedToken[]) public unstakedInfo;
    mapping(address => uint256) public rewards;

    IERC20 public token;
    address public owner;
    uint256 public rewardPercentPerYear = 12; // 12% per year
    uint256 public secondsPerDay = 86400; // 24*60*60 secs = 86400 secs =  one day
    uint256 public lockPeriod = 16; // 16 days

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
        owner = msg.sender;
    }

    event Staked(address by, uint256 amount);
    event Unstaked(address by, uint256 amount);
    event RewardClaimed(address by, uint256 amount);
    event SetLockPeriodUpdated(address by, uint256 newLockPeriod);
    event SetRewardPercentUpdated(address by, uint256 newRewardPercent);
    event SetSecondsPerDayUpdated(address by, uint256 newSecondsPerDay);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SetRewardTokenAddress(address by, address token);

    event WithdrawnAll(address by, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        // If user already has an active stake, add to it
        if (stakes[msg.sender].active) {
            stakes[msg.sender].amount += amount;
            unstakedInfo[msg.sender].push(UnstakedToken(amount, 0, false));
        } else {
            stakes[msg.sender] = Stake(
                amount,
                block.timestamp,
                true
                // new UnstakedToken[](0)
            );
        }

        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        require(stakes[msg.sender].active, "No active stake");
        require(
            amount > 0 && amount <= stakes[msg.sender].amount,
            "Invalid unstake amount"
        );

        Stake storage userStake = stakes[msg.sender];
        userStake.amount -= amount;

        unstakedInfo[msg.sender].push(
            UnstakedToken(
                amount,
                block.timestamp + (lockPeriod * secondsPerDay),
                false
            )
        );

        emit Unstaked(msg.sender, amount);
    }

    function withdrawUnstakedTokens(uint256 index) external {
        require(stakes[msg.sender].active, "No active stake");
        require(index < unstakedInfo[msg.sender].length, "Invalid index");

        UnstakedToken storage unstakedToken = unstakedInfo[msg.sender][index];
        require(!unstakedToken.withdrawn, "Token has already been withdrawn");
        require(
            block.timestamp >= unstakedToken.unlockTime,
            "Token is still locked"
        );

        unstakedToken.withdrawn = true;
        token.safeTransfer(msg.sender, unstakedToken.amount);

        emit Unstaked(msg.sender, unstakedToken.amount);
    }

    function claimReward() external {
        require(stakes[msg.sender].active, "No active stake");

        uint256 reward = calculateReward(msg.sender);
        rewards[msg.sender] += reward;

        emit RewardClaimed(msg.sender, reward);
    }

    function calculateReward(address user) public view returns (uint256) {
        if (!stakes[user].active) return 0;

        uint256 stakeDuration = block.timestamp - stakes[user].startTime;
        uint256 reward = (stakes[user].amount *
            rewardPercentPerYear *
            stakeDuration) / (secondsPerDay * 365 * 100);
        return reward;
    }

    function setLockPeriod(uint256 lockDays) external onlyOwner {
        require(lockDays > 0, "Lock period must be greater than zero");

        lockPeriod = lockDays;
        emit SetLockPeriodUpdated(msg.sender, lockDays);
    }

    function setSecondsPerDay(uint256 _secondsPerDay) external onlyOwner {
        require(
            _secondsPerDay > 0,
            "Seconds per day must be greater than zero"
        );
        secondsPerDay = _secondsPerDay;

        emit SetSecondsPerDayUpdated(msg.sender, _secondsPerDay);
    }

    function setRewardPercentPerYear(uint256 percent) external onlyOwner {
        require(percent > 0, "Reward percent must be greater than zero");
        rewardPercentPerYear = percent;

        emit SetRewardPercentUpdated(msg.sender, percent);
    }

    function setTokenAddress(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        token = IERC20(tokenAddress);
        emit SetRewardTokenAddress(msg.sender, tokenAddress);
    }

    function getStakedAmount(address user) external view returns (uint256) {
        return stakes[user].amount;
    }

    function getRemainedLockTime(
        address user,
        uint256 index
    ) external view returns (uint256) {
        require(stakes[user].active, "No active stake");
        require(index < unstakedInfo[user].length, "Invalid index");

        UnstakedToken storage unstakedToken = unstakedInfo[user][index];
        require(!unstakedToken.withdrawn, "Token has already been withdrawn");

        if (block.timestamp < unstakedToken.unlockTime) {
            return unstakedToken.unlockTime - block.timestamp;
        } else {
            return 0;
        }
    }

    function getUnstakedTokens(
        address user
    ) external view returns (UnstakedToken[] memory) {
        require(stakes[user].active, "No active stake");

        return unstakedInfo[user];
    }

    function getTotalArrayUnstakedTokens(
        address user
    ) external view returns (uint256) {
        require(stakes[user].active, "No active stake");

        return unstakedInfo[user].length;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function withdrawAllStakedTokens() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));

        token.safeTransfer(owner, balance);

        emit WithdrawnAll(owner, balance);
    }
}
