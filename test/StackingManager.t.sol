// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Goo} from "../src/Goo.sol";
import {GooNFT} from "../src/GooNFT.sol";
import {StakingManager} from "../src/StakingManager.sol";
import {LibGOO} from "../src/LibGOO.sol";

contract StakingManagerTest is Test {
    address owner = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
    address alice = address(10);
    address bob = address(11);
    StakingManager manager;
    GooNFT nft;
    Goo goo;

    function setUp() public {
        manager = new StakingManager();
        goo = new Goo(address(manager), 1000000e18);
        nft = new GooNFT(1e18, address(goo)); // initMintPrice = 1
        manager.setGoo(address(goo));
        manager.setNFT(address(nft));
    }

    function _mintNFT(address to, uint256 weight) private {
        uint256 mintPrice = nft.mintPrice();
        goo.transfer(to, mintPrice);
        vm.prank(to);
        goo.approve(address(nft), mintPrice);
        manager.mintNFT(to, weight);
    }

    function _staking(
        address staker,
        uint256 tokenID,
        uint256 stakingAmount
    ) private {
        vm.startPrank(staker);
        nft.approve(address(manager), tokenID);
        goo.approve(address(manager), stakingAmount);
        manager.staking(tokenID, stakingAmount);
        vm.stopPrank();
    }

    function testMintGoo() public {
        uint256 mintAmount = 1e18;
        assertTrue(goo.balanceOf(alice) == 0);
        goo.transfer(alice, mintAmount);
        assertTrue(goo.balanceOf(alice) == mintAmount);
    }

    function testMintNFT() public {
        _mintNFT(alice, 1);
        assertTrue(nft.balanceOf(alice) == 1);
        assertTrue(goo.balanceOf(alice) == 0);
    }

    function testStaking() public {
        uint256 stakingAmount = 1e18;
        goo.transfer(alice, stakingAmount);
        _mintNFT(alice, 1);

        uint256 tokenID = nft.tokenOfOwnerByIndex(alice, 0);
        _staking(alice, tokenID, stakingAmount);

        assertTrue(nft.ownerOf(tokenID) == address(manager));
        assertTrue(goo.balanceOf(address(manager)) == stakingAmount);
    }

    function testStakingReward() public {
        uint256 stakingAmount = 1e18;
        uint256 nftWeight = 1;
        goo.transfer(alice, stakingAmount);
        _mintNFT(alice, nftWeight);

        uint256 tokenID = nft.tokenOfOwnerByIndex(alice, 0);
        _staking(alice, tokenID, stakingAmount);

        uint256 startTimestamp = block.timestamp;
        uint256 timeDuration = 1 * 24 * 60 * 60;
        vm.warp(startTimestamp + timeDuration); // time pass
        (uint256 totalReward, uint256 pendingReward) = manager.checkReward(tokenID);
        uint256 rewardExcepted = LibGOO.computeGOOBalance(nftWeight, stakingAmount, timeDuration);
        assertTrue(pendingReward == rewardExcepted);
        assertTrue(totalReward == rewardExcepted);
    }

    function testClaim() public {
        uint256 stakingAmount = 1e18;
        uint256 nftWeight = 1;
        goo.transfer(alice, stakingAmount);
        _mintNFT(alice, nftWeight);

        uint256 tokenID = nft.tokenOfOwnerByIndex(alice, 0);
        _staking(alice, tokenID, stakingAmount);

        uint256 startTimestamp = block.timestamp;
        uint256 timeDuration = 1 * 24 * 60 * 60;
        vm.warp(startTimestamp + timeDuration); // time pass
        (uint256 totalRewardExcepted, uint256 pendingRewardExcepted) = manager.checkReward(tokenID);

        vm.startPrank(alice);
        uint256 beforeBalance = goo.balanceOf(alice);
        manager.claim(tokenID, alice);

        assertTrue(goo.balanceOf(alice) - beforeBalance == pendingRewardExcepted);
        uint256 totalReward;
        uint256 claimedReward;
        (, , , totalReward, claimedReward, ) = manager.stakingStatusList(tokenID);
        assertTrue(totalReward == totalRewardExcepted);
        assertTrue(claimedReward == totalRewardExcepted);
        (, pendingRewardExcepted) = manager.checkReward(tokenID);
        assertTrue(pendingRewardExcepted == 0);
    }
}
