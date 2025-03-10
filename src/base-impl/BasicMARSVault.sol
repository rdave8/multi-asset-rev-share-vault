// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28;

import {MARSVault} from "../standard/MARSVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BasicMARSVault is MARSVault, Ownable {
    constructor(address owner) ERC20("MARS Share", "MARS") Ownable(owner) {}

    function allowAsset(IERC20 asset) external onlyOwner {
        _allowAsset(asset);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

