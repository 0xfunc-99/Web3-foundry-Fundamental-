// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
contract fundmeTest is Test {
    FundMe fundme;
    DeployFundMe deployFundMe;
    address USER = makeAddr("USER");
    function setUp() external {
        deployFundMe = new DeployFundMe();
        (fundme, ) = deployFundMe.run();
        vm.deal(USER, 10 ether);
    }

    function test_MinimalFunding() public view {
        assertEq(fundme.MINIMUM_USD(), 5 * 10 ** 18);
    }

    function test_OnwerIsmsg_sender() public view {
        assertEq(fundme.getOwner(), address(deployFundMe));
    }
    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundme.getVersion();
        assertEq(version, 4);
    }
    function testfundfailwithOutEnoughEth() public {
        vm.expectRevert();
        fundme.fund();
    }

    function testfundupdateFundedData() public {
        vm.prank(USER);
        fundme.fund{value: 1 ether}();
        uint256 amountFunded = fundme.getAddressToAmountFunded(USER);
        assertEq(amountFunded, 1 ether);
    }
    function testAddsFunderToArrayOfFoundry() public {
        vm.prank(USER);
        fundme.fund{value: 1 ether}();
        address funder = fundme.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundme.fund{value: 1 ether}();
        _;
    }

    function testOwnerCanOlnyWithDraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundme.withdraw();
    }

    function testWithdrawWithAsngleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        // Act

        vm.prank(fundme.getOwner());
        fundme.withdraw();

        // Assert
        // Correct the typo from .balacne to .balance
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundMeBalance = address(fundme).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOffunders = 10;
        uint160 StartingFunderIdex = 1;

        for (uint160 i = StartingFunderIdex; i < numberOffunders; i++) {
            hoax(address(i), 1 ether);
            fundme.fund{value: 1 ether}();
        }
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        vm.prank(fundme.getOwner());
        fundme.withdraw();

        assert(address(fundme).balance == 0);
        assert(
            startingOwnerBalance + startingFundMeBalance ==
                fundme.getOwner().balance
        );
    }
}
