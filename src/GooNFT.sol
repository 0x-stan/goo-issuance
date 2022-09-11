// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Goo} from "./Goo.sol";
import {ERC721, ERC721Enumerable} from "openzeppelin-contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC20Burnable} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Counters} from "openzeppelin-contracts/utils/Counters.sol";

contract GooNFT is ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address public gooAddr;

    // mint NFT(ERC721) will burn Goo(ERC20)
    uint256 public mintPrice;
    // Mapping from token ID to weights multiple
    mapping(uint256 => uint256) public weights;

    event MintPriceChanged(uint256 indexed newMintPrice, uint256 indexed oldMintPrice);

    constructor(uint256 initMintPrice, address gooAddr_) ERC721("GooNFT", "GooNFT") {
        gooAddr = gooAddr_;
        mintPrice = initMintPrice;
    }

    function mint(address to, uint256 weight) public returns (uint256) {
        // save gas
        uint256 oldMintPrice = mintPrice;
        // burn goo token
        Goo(gooAddr).burn(to, oldMintPrice);
        uint256 newMintPrice = _nextMintPrice(oldMintPrice);
        mintPrice = newMintPrice;
        emit MintPriceChanged(newMintPrice, oldMintPrice);

        uint256 newItemId = _tokenIds.current();
        _mint(to, newItemId);

        // set NFT weight to staking
        weights[newItemId] = weight;

        _tokenIds.increment();
        return newItemId;
    }

    function _nextMintPrice(uint256 oldMintPrice) private pure returns (uint256) {
        // TODO: next mint price = ...
        return oldMintPrice + 1e18;
    }

    function nextMintPrice() public view returns (uint256) {
        return _nextMintPrice(mintPrice);
    }
}
