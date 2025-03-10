// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28;

import {Test} from "forge-std/src/Test.sol";
import {console2} from "forge-std/src/console2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {BasicMARSVault} from "../src/base-impl/BasicMARSVault.sol";
import {TestToken} from "../src/base-impl/TestToken.sol";

contract MARSVaultTest is Test {
    BasicMARSVault vault;
    TestToken[10] tokens;

    address vaultOwner = vm.addr(1);
    address revenueDepositor = vm.addr(2);
    address shareHolderA = vm.addr(3);
    address shareHolderB = vm.addr(4);
    address shareHolderC = vm.addr(5);

    function setUp() public {
        console2.log("SETUP");
        console2.log("--------------------------------------------------");

        vault = new BasicMARSVault(vaultOwner);
        console2.log("%s: %s", vault.name(), address(vault));
        
        vm.startPrank(vaultOwner);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = new TestToken(
                string.concat("Test Token ", Strings.toString(i)),
                string.concat("TT", Strings.toString(i))
            );
            vault.allowAsset(tokens[i]);
            tokens[i].mint(revenueDepositor, type(uint256).max);

            console2.log("%s: %s", tokens[i].name(), address(tokens[i]));
        }
        console2.log();
        vm.stopPrank();

        printBalances();

        console2.log("--------------------------------------------------");
        console2.log();
    }

    function printBalances() public view {
        console2.log("BALANCES");

        console2.log("vault");
        for (uint256 i = 0; i < tokens.length; i++) {
            console2.log("%s: %s", tokens[i].name(), tokens[i].balanceOf(address(vault)));
        }
        console2.log();

        console2.log("shareHolderA");
        console2.log("%s: %s", vault.name(), vault.balanceOf(shareHolderA));
        for (uint256 i = 0; i < tokens.length; i++) {
            console2.log("%s: %s", tokens[i].name(), tokens[i].balanceOf(shareHolderA));
            console2.log("Unclaimed %s: %s", tokens[i].name(), vault.previewClaimRevenue(tokens[i], shareHolderA));
        }
        console2.log();

        console2.log("shareHolderB");
        console2.log("%s: %s", vault.name(), vault.balanceOf(shareHolderB));
        for (uint256 i = 0; i < tokens.length; i++) {
            console2.log("%s: %s", tokens[i].name(), tokens[i].balanceOf(shareHolderB));
            console2.log("Unclaimed %s: %s", tokens[i].name(), vault.previewClaimRevenue(tokens[i], shareHolderB));
        }
        console2.log();
        console2.log("shareHolderC");
        console2.log("%s: %s", vault.name(), vault.balanceOf(shareHolderC));
        for (uint256 i = 0; i < tokens.length; i++) {
            console2.log("%s: %s", tokens[i].name(), tokens[i].balanceOf(shareHolderC));
            console2.log("Unclaimed %s: %s", tokens[i].name(), vault.previewClaimRevenue(tokens[i], shareHolderC));
        }
    }

    function test_example_scenario() public {
        console2.log("EXAMPLE SCENARIO");
        console2.log("--------------------------------------------------");

        // Deposit 1000 of each token as revenue
        console2.log("Deposit 1000 of each token as revenue");
        console2.log();
        vm.startPrank(revenueDepositor);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].approve(address(vault), 1000);
            vault.depositRevenue(tokens[i], 1000);
        }
        vm.stopPrank();
        printBalances();
        console2.log();

        // Mint 750 shares to shareHolderA and 250 to shareHolderB, split is 75 / 25 / 0
        console2.log("Mint 750 shares to shareHolderA and 250 to shareHolderB, split is 75 / 25 / 0");
        console2.log();
        vm.startPrank(vaultOwner);
        vault.mint(shareHolderA, 750);
        vault.mint(shareHolderB, 250);
        vm.stopPrank();
        printBalances();
        console2.log();

        // Deposit incrementing amounts of each token as revenue
        console2.log("Deposit incrementing amounts of each token as revenue");
        console2.log();
        vm.startPrank(revenueDepositor);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].approve(address(vault), i * 100);
            vault.depositRevenue(tokens[i], i * 100);
        }
        vm.stopPrank();
        printBalances();
        console2.log();

        // shareHolderA individually claims revenue on tokens 0 through (tokens.length / 2)
        console2.log("shareHolderA individually claims revenue on tokens 0 through (tokens.length / 2)");
        console2.log();
        vm.startPrank(shareHolderA);
        for (uint256 i = 0; i < tokens.length / 2; i++) {
            vault.claimRevenue(tokens[i]);
        }
        vm.stopPrank();
        printBalances();
        console2.log();

        // Deposit decrementing amounts of each token
        console2.log("Deposit decrementing amounts of each token");
        console2.log();
        vm.startPrank(revenueDepositor);
        uint256 j = tokens.length;
        for (uint256 i = 0; i < tokens.length; i++) {
            j--;
            tokens[i].approve(address(vault), j * 100);
            vault.depositRevenue(tokens[i], j * 100);
        }
        vm.stopPrank();
        printBalances();
        console2.log();

        // shareHolderB batch claims revenue
        console2.log("shareHolderB batch claims revenue");
        console2.log();
        vm.startPrank(shareHolderB);
        vault.batchClaimRevenue();
        vm.stopPrank();
        printBalances();
        console2.log();

        // Deposit 1000 of each token as revenue
        console2.log("Deposit 1000 of each token as revenue");
        console2.log();
        vm.startPrank(revenueDepositor);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].approve(address(vault), 1000);
            vault.depositRevenue(tokens[i], 1000);
        }
        vm.stopPrank();
        printBalances();
        console2.log();

        // shareHolderA transfers 250 shares to shareHolderB, split is now 50 / 50 / 0
        console2.log("shareHolderA transfers 250 shares to shareHolderB, split is now 50 / 50 / 0");
        console2.log();
        vm.startPrank(shareHolderA);
        vault.transfer(shareHolderB, 250);
        vm.stopPrank();
        printBalances();
        console2.log();

        // Deposit 1000 of each token as revenue
        console2.log("Deposit 1000 of each token as revenue");
        console2.log();
        vm.startPrank(revenueDepositor);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].approve(address(vault), 1000);
            vault.depositRevenue(tokens[i], 1000);
        }
        vm.stopPrank();
        printBalances();
        console2.log();

        // Mint 1000 shares to shareHolderC, split is 25 / 25 / 50
        console2.log("Mint 1000 shares to shareHolderC, split is 25 / 25 / 50");
        console2.log();
        vm.startPrank(vaultOwner);
        vault.mint(shareHolderC, 1000);
        vm.stopPrank();
        printBalances();
        console2.log();

        // Deposit 1000 of each token as revenue
        console2.log("Deposit 1000 of each token as revenue");
        console2.log();
        vm.startPrank(revenueDepositor);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].approve(address(vault), 1000);
            vault.depositRevenue(tokens[i], 1000);
        }
        vm.stopPrank();
        printBalances();
        console2.log();

        // shareHolderA, shareHolderB, shareHolderC claim
        console2.log("shareHolderA, shareHolderB, shareHolderC claim revenue");
        console2.log();
        vm.startPrank(shareHolderA);
        vault.batchClaimRevenue();
        vm.stopPrank();
        vm.startPrank(shareHolderB);
        vault.batchClaimRevenue();
        vm.stopPrank();
        vm.startPrank(shareHolderC);
        vault.batchClaimRevenue();
        vm.stopPrank();
        printBalances();
        console2.log();
    }
}

