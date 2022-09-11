// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Goo} from "./Goo.sol";
import {GooNFT} from "./GooNFT.sol";
import {LibGOO} from "./LibGOO.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract StakingManager {
    using FixedPointMathLib for uint256;

    address public admin;
    address public gooAddr;
    address public nftAddr;

    struct StakingStatus {
        uint256 tokenID;
        uint256 gooBalance;
        address owner;
        uint256 totalReward;
        uint256 claimedReward;
        uint256 lastTimestamp;
    }

    // Mapping from token ID to StakingStatus
    mapping(uint256 => StakingStatus) public stakingStatusList;

    event Staking(address indexed receiver, uint256 indexed tokenID, uint256 indexed pendingReward);
    event Claim(address indexed receiver, uint256 indexed tokenID, uint256 indexed pendingReward);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "StakingManager:OnlyAdmin");
        _;
    }

    function staking(uint256 tokenID, uint256 gooAmount) external {
        if (GooNFT(nftAddr).ownerOf(tokenID) != address(this)) {
            GooNFT(nftAddr).transferFrom(msg.sender, address(this), tokenID);
        }
        Goo(gooAddr).transferFrom(msg.sender, address(this), gooAmount);

        StakingStatus memory status = stakingStatusList[tokenID];
        // init
        if (status.lastTimestamp == 0) {
            status.tokenID = tokenID;
            status.owner = msg.sender;
            status.gooBalance = status.gooBalance + gooAmount;
            status.lastTimestamp = block.timestamp;
        } else {
            claim(tokenID, msg.sender);
            status.gooBalance = status.gooBalance + gooAmount;
            status.lastTimestamp = block.timestamp;
        }
        stakingStatusList[tokenID] = status;
    }

    function checkReward(uint256 tokenID) public view returns (uint256 totalReward, uint256 pendingReward) {
        StakingStatus memory status = stakingStatusList[tokenID];
        require(status.lastTimestamp > 0, "StakingStatus not init");
        uint256 deltaTime = block.timestamp - status.lastTimestamp;
        if (deltaTime <= 0) {
            totalReward = status.totalReward;
            pendingReward = 0;
        } else {
            uint256 emissionMultiple = GooNFT(nftAddr).weights(tokenID);
            totalReward = LibGOO.computeGOOBalance(emissionMultiple, status.gooBalance, deltaTime);
            pendingReward = totalReward - status.totalReward;
        }
    }

    function claim(uint256 tokenID, address to) public {
        require(to != address(0), "StakingManager:claim to zeroAddress");
        StakingStatus memory status = stakingStatusList[tokenID];
        require(msg.sender == status.owner, "StakingManager:wrong nft owner");
        (uint256 totalReward, uint256 pendingReward) = checkReward(tokenID);
        if (pendingReward > 0) {
            status.totalReward = totalReward;
            status.claimedReward = totalReward;
            status.lastTimestamp = block.timestamp;
            Goo(gooAddr).mint(to, pendingReward);
            emit Claim(to, tokenID, pendingReward);

            stakingStatusList[tokenID] = status;
        }
    }

    function withdrawGoo(
        uint256 tokenID,
        address to,
        uint256 amount
    ) external {
        require(to != address(0), "StakingManager:claim to zeroAddress");
        StakingStatus memory status = stakingStatusList[tokenID];
        require(msg.sender == status.owner, "StakingManager:wrong nft owner");
        require(status.gooBalance >= amount, "StakingManager:not enought goo");
        claim(tokenID, to);
        status.gooBalance = status.gooBalance - amount;
        Goo(gooAddr).transfer(to, amount);

        stakingStatusList[tokenID] = status;
    }

    function withdrawNFT(
        uint256 tokenID,
        address to,
        uint256 amount
    ) public {
        require(to != address(0), "StakingManager:claim to zeroAddress");
        StakingStatus memory status = stakingStatusList[tokenID];
        require(msg.sender == status.owner, "StakingManager:wrong nft owner");
        require(status.gooBalance >= amount, "StakingManager:not enought goo");
        claim(tokenID, to);
        Goo(gooAddr).transfer(to, status.gooBalance);
        GooNFT(nftAddr).transferFrom(address(this), to, tokenID);

        delete stakingStatusList[tokenID];
    }

    function _mintGoo(address to, uint256 amount) private {
        Goo(gooAddr).mint(to, amount);
    }

    function mintNFT(address to, uint256 weight) external {
        GooNFT(nftAddr).mint(to, weight);
    }

    function setGoo(address gooAddr_) external onlyAdmin {
        gooAddr = gooAddr_;
    }

    function setNFT(address nftAddr_) external onlyAdmin {
        nftAddr = nftAddr_;
    }
}
