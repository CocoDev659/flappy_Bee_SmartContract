// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// interface TokenBEET {
//     function transferFrom(
//         address sender,
//         address recipient,
//         uint256 amount
//     ) external returns (bool);

//     function transfer(
//         address recipient,
//         uint256 amount
//     ) external returns (bool);

//     function balanceOf(address account) external view returns (uint256);
// }

contract StakingBEET {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 unlockTime;
        bool active;
    }

    mapping(address => Stake) public stakes;
    mapping(address => uint256) public rewards;

    IERC20 public token;
    address public owner;
    uint256 public rewardPercentPerYear = 12; // 12% pe year
    uint256 public constant secondsPerDay = 86400; // 24*60*60 secs = one day, 86400
    uint256 public constant lockPeriod = 16; // 16 days

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
        owner = msg.sender;
    }

    event Staked(address by, uint256 amount);
    event Withdrawn(address by, uint256 amount);
    event RewardEarned(address by, uint256 amount);
    event SetLockPeriodUpdated(address by, uint256 newLockPeriod);
    event SetRewardPercentUpdated(address by, uint256 newRewardPercent);
    event SetSecondsPerDayUpdated(address by, uint256 newSecondsPerDay);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        // If user already has an active stake, add to it
        if (stakes[msg.sender].active) {
            stakes[msg.sender].amount += amount;
            stakes[msg.sender].unlockTime =
                block.timestamp +
                (lockPeriod * secondsPerDay);
        } else {
            uint256 unlockTime = block.timestamp + (lockPeriod * secondsPerDay);
            stakes[msg.sender] = Stake(
                amount,
                block.timestamp,
                unlockTime,
                true
            );
        }

        token.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw() external {
        require(stakes[msg.sender].active, "No active stake");
        require(
            block.timestamp >= stakes[msg.sender].unlockTime,
            "Unlock period not over"
        );

        uint256 reward = calculateReward(msg.sender);
        rewards[msg.sender] += reward;

        uint256 totalAmount = stakes[msg.sender].amount + reward;
        delete stakes[msg.sender];

        token.transfer(msg.sender, totalAmount);

        emit Withdrawn(msg.sender, amount);
        emit RewardEarned(msg.sender, reward);
    }

    function calculateReward(address user) public view returns (uint256) {
        if (!stakes[user].active) return 0;

        uint256 stakeDuration = block.timestamp - stakes[user].startTime;
        uint256 reward = (stakes[user].amount *
            rewardPercentPerYear *
            stakeDuration) / (secondsPerDay * 365);
        return reward;
    }

    function earnDailyRewards() external {
        require(stakes[msg.sender].active, "No active stake");

        uint256 reward = calculateReward(msg.sender);
        rewards[msg.sender] += reward;

        stakes[msg.sender].startTime = block.timestamp;
    }

    function setLockPeriod(uint256 lockDays) external onlyOwner {
        require(lockDays > 0, "Lock period must be greater than zero");

        stakes[msg.sender].unlockTime =
            stakes[msg.sender].startTime +
            (lockDays * secondsPerDay);

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

        emit SetRewardPercentUpdated(msg.sender, newRewardPercent);
    }

    function getStakedAmount(address user) external view returns (uint256) {
        return stakes[user].amount;
    }

    function getRemainedPeriod(address user) external view returns (uint256) {
        if (stakes[user].active && block.timestamp < stakes[user].unlockTime) {
            return stakes[user].unlockTime - block.timestamp;
        }
        return 0;
    }
}
