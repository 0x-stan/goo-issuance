// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Goo} from "../src/Goo.sol";
import {GooNFT} from "../src/GooNFT.sol";
import {StakingManager} from "../src/StakingManager.sol";

contract ContractTest is Test {
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

    function testOnlyStakingManager() public {}
}
