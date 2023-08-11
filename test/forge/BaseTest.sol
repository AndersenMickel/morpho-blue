// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "src/Morpho.sol";
import {ERC20Mock as ERC20} from "src/mocks/ERC20Mock.sol";
import {OracleMock as Oracle} from "src/mocks/OracleMock.sol";
import {IrmMock as Irm} from "src/mocks/IrmMock.sol";

contract BaseTest is Test {
    using FixedPointMathLib for uint256;
    using MarketLib for Market;

    uint256 internal constant HIGH_COLLATERAL_AMOUNT = 1e25;
    uint256 internal constant MIN_TEST_AMOUNT = 1000;
    uint256 internal constant MAX_TEST_AMOUNT = 2 ** 64;
    uint256 internal constant MIN_TEST_SHARES = MIN_TEST_AMOUNT * 1e18;
    uint256 internal constant MAX_TEST_SHARES = MAX_TEST_AMOUNT * 1e18;
    uint256 internal constant MIN_COLLATERAL_PRICE = 100;
    uint256 internal constant MAX_COLLATERAL_PRICE = 2 ** 64;

    address internal BORROWER = _addrFromHashedString("Morpho Borrower");
    address internal LIQUIDATOR = _addrFromHashedString("Morpho Liquidator");
    address internal OWNER = _addrFromHashedString("Morpho Owner");

    uint256 internal constant LLTV = 0.8 ether;

    Morpho internal morpho;
    ERC20 internal borrowableAsset;
    ERC20 internal collateralAsset;
    Oracle internal oracle;
    Irm internal irm;
    Market internal market;
    Id internal id;

    function setUp() public {
        vm.label(OWNER, "Owner");
        vm.label(BORROWER, "Borrower");
        vm.label(LIQUIDATOR, "Liquidator");

        // Create Morpho.
        morpho = new Morpho(OWNER);
        vm.label(address(morpho), "Morpho");

        // List a market.
        borrowableAsset = new ERC20("borrowable", "B", 18);
        vm.label(address(borrowableAsset), "Borrowable asset");

        collateralAsset = new ERC20("collateral", "C", 18);
        vm.label(address(collateralAsset), "Collateral asset");

        oracle = new Oracle();
        vm.label(address(oracle), "Oracle");

        oracle.setPrice(1e25);

        irm = new Irm(morpho);
        vm.label(address(irm), "IRM");

        market = Market(address(borrowableAsset), address(collateralAsset), address(oracle), address(irm), LLTV);
        id = market.id();

        vm.startPrank(OWNER);
        morpho.enableIrm(address(irm));
        morpho.enableLltv(LLTV);
        morpho.createMarket(market);
        vm.stopPrank();

        oracle.setPrice(1e25);

        borrowableAsset.approve(address(morpho), type(uint256).max);
        collateralAsset.approve(address(morpho), type(uint256).max);
        vm.startPrank(BORROWER);
        borrowableAsset.approve(address(morpho), type(uint256).max);
        collateralAsset.approve(address(morpho), type(uint256).max);
        vm.stopPrank();
        vm.startPrank(LIQUIDATOR);
        borrowableAsset.approve(address(morpho), type(uint256).max);
        collateralAsset.approve(address(morpho), type(uint256).max);
        vm.stopPrank();

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1 days);
    }

    function _addrFromHashedString(string memory str) internal pure returns (address) {
        return address(uint160(uint256(keccak256(bytes(str)))));
    }

    function _provideLiquidity(uint256 amount) internal {
        borrowableAsset.setBalance(address(this), amount);
        morpho.supply(market, amount, 0, address(this), hex"");
    }

    function _provideCollateralForBorrower(address borrower) internal {
        collateralAsset.setBalance(borrower, HIGH_COLLATERAL_AMOUNT);
        vm.startPrank(borrower);
        collateralAsset.approve(address(morpho), type(uint256).max);
        morpho.supplyCollateral(market, HIGH_COLLATERAL_AMOUNT, borrower, hex"");
        vm.stopPrank();
    }

    function _boundHealthyPosition(uint256 amountCollateral, uint256 amountBorrowed, uint256 priceCollateral)
        internal
        view
        returns (uint256, uint256, uint256)
    {
        priceCollateral = bound(priceCollateral, MIN_COLLATERAL_PRICE, MAX_COLLATERAL_PRICE);
        amountBorrowed = bound(amountBorrowed, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);

        uint256 minCollateral = amountBorrowed.wDivUp(market.lltv).wDivUp(priceCollateral);

        amountCollateral = bound(amountCollateral, minCollateral, max(minCollateral, MAX_TEST_AMOUNT));

        return (amountCollateral, amountBorrowed, priceCollateral);
    }

    function _boundUnhealthyPosition(uint256 amountCollateral, uint256 amountBorrowed, uint256 priceCollateral)
        internal
        view
        returns (uint256, uint256, uint256)
    {
        priceCollateral = bound(priceCollateral, MIN_COLLATERAL_PRICE, MAX_COLLATERAL_PRICE);
        amountBorrowed = bound(amountBorrowed, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);

        uint256 maxCollateral = amountBorrowed.wDivDown(market.lltv).wDivDown(priceCollateral);
        vm.assume(maxCollateral != 0);

        amountCollateral = bound(amountBorrowed, 1, maxCollateral);

        return (amountCollateral, amountBorrowed, priceCollateral);
    }

    function _boundValidLltv(uint256 lltv) internal view returns (uint256) {
        return bound(lltv, 0, WAD - 1);
    }

    function _boundInvalidLltv(uint256 lltv) internal view returns (uint256) {
        return bound(lltv, WAD, type(uint256).max);
    }

    function _liquidationIncentive(uint256 lltv) internal pure returns (uint256) {
        return WAD + ALPHA.wMulDown(WAD.wDivDown(lltv) - WAD);
    }

    function neq(Market memory a, Market memory b) internal pure returns (bool) {
        return (Id.unwrap(a.id()) != Id.unwrap(b.id()));
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
