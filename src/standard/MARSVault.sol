// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// TODO: check for reentrancy vulnerabilities (specifically for transfers)
// TODO: optimize the storage accesses (especially for _batchClaimRevenue(address holder))

abstract contract MARSVault is ERC20 {
    struct AssetInfo {
        bool isAllowed;
        uint256 unclaimedRevenue;
        uint256 cumulativeRevenuePerShare;
    }

    mapping(IERC20 asset => AssetInfo) private _assets;

    mapping(address holder => mapping(IERC20 asset => uint256 lastClaimSnapshot)) private _claimSnapshots;

    IERC20[] private _allowedAssets;

    error MARSVaultAssetNotAllowed();

    function revPerShareDecimals() public pure virtual returns (uint256) {
        return 18;
    }

    function _allowAsset(IERC20 asset) internal {
        _assets[asset].isAllowed = true;
        _allowedAssets.push(asset);
    }

    function depositRevenue(IERC20 asset, uint256 amount) external {
        if (!_assets[asset].isAllowed) revert MARSVaultAssetNotAllowed();

        _assets[asset].unclaimedRevenue += amount;
        if (totalSupply() > 0) {
            _assets[asset].cumulativeRevenuePerShare += Math.mulDiv(amount, 10 ** revPerShareDecimals(), totalSupply());
        }

        SafeERC20.safeTransferFrom(asset, msg.sender, address(this), amount);
    }

    function previewClaimRevenue(IERC20 asset, address holder) public view returns (uint256) {
        if (!_assets[asset].isAllowed) revert MARSVaultAssetNotAllowed();
        uint256 holderShares = balanceOf(holder);
        if (holderShares == 0) return 0;

        uint256 lastClaimSnapshot = _claimSnapshots[holder][asset];
        uint256 revenuePerShare = _assets[asset].cumulativeRevenuePerShare - lastClaimSnapshot;

        return Math.mulDiv(holderShares, revenuePerShare, 10 ** revPerShareDecimals());
    }

    function claimRevenue(IERC20 asset) external returns (uint256) {
        return _claimRevenue(asset, msg.sender);
    }

    function _claimRevenue(IERC20 asset, address holder) internal returns (uint256) {
        if (!_assets[asset].isAllowed) revert MARSVaultAssetNotAllowed();
        uint256 claimableRevenue = previewClaimRevenue(asset, holder);

        _claimSnapshots[holder][asset] = _assets[asset].cumulativeRevenuePerShare;
        _assets[asset].unclaimedRevenue -= claimableRevenue;

        SafeERC20.safeTransfer(asset, holder, claimableRevenue);

        return claimableRevenue;
    }

    function batchClaimRevenue(IERC20[] calldata assets) external {
        _batchClaimRevenue(assets, msg.sender);
    }

    function batchClaimRevenue() external {
        _batchClaimRevenue(msg.sender);
    }

    function _batchClaimRevenue(IERC20[] calldata assets, address holder) internal {
        for (uint256 i = 0; i < assets.length; i++) {
            _claimRevenue(assets[i], holder);
        }
    }

    function _batchClaimRevenue(address holder) internal {
        for (uint256 i = 0; i < _allowedAssets.length; i++) {
            _claimRevenue(_allowedAssets[i], holder);
        }
    }

    function _update(address from, address to, uint256 value) internal override {
        if (from != address(0)) _batchClaimRevenue(from);
        if (to != address(0)) _batchClaimRevenue(to);

        super._update(from, to, value); 
    }
}
