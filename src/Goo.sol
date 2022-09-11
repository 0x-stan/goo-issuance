// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20Burnable, ERC20} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Goo is ERC20Burnable {
    address public admin;
    address public stakingManager;

    constructor(
        address stakingManager_,
        uint256 totalSupply_
    ) ERC20("Goo", "Goo") {
        stakingManager = stakingManager_;
        _mint(msg.sender, totalSupply_);
    }

    modifier onlyStakingManager() {
        require(stakingManager != address(0), "Goo:stakingManagerZeroAddress");
        require(msg.sender == stakingManager, "Goo:onlyStakingManager");
        _;
    }

    function mint(address to, uint256 amount) external onlyStakingManager {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) external {
        super.burnFrom(account, amount);
    }
}
