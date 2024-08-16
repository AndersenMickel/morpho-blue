// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "../../src/Morpho.sol";
import "../../src/libraries/SharesMathLib.sol";
import "../../src/libraries/MarketParamsLib.sol";

contract MorphoHarness is Morpho {
    using MarketParamsLib for MarketParams;

    constructor(address newOwner) Morpho(newOwner) {}

    // Returns the constant WAD value used in the contract
    function wad() external pure returns (uint256) {
        return WAD;
    }

    // Returns the maximum fee value allowed in the contract
    function maxFee() external pure returns (uint256) {
        return MAX_FEE;
    }

    // Returns MarketParams for a given market Id
    function toMarketParams(Id id) external view returns (MarketParams memory) {
        return idToMarketParams[id];
    }

    // Returns the total supply assets for a given market Id
    function totalSupplyAssets(Id id) external view returns (uint256) {
        return market[id].totalSupplyAssets;
    }

    // Returns the total supply shares for a given market Id
    function totalSupplyShares(Id id) external view returns (uint256) {
        return market[id].totalSupplyShares;
    }

    // Returns the total borrowed assets for a given market Id
    function totalBorrowAssets(Id id) external view returns (uint256) {
        return market[id].totalBorrowAssets;
    }

    // Returns the total borrowed shares for a given market Id
    function totalBorrowShares(Id id) external view returns (uint256) {
        return market[id].totalBorrowShares;
    }

    // Returns the supply shares of a specific account in a given market
    function supplyShares(Id id, address account) external view returns (uint256) {
        return position[id][account].supplyShares;
    }

    // Returns the borrow shares of a specific account in a given market
    function borrowShares(Id id, address account) external view returns (uint256) {
        return position[id][account].borrowShares;
    }

    // Returns the collateral of a specific account in a given market
    function collateral(Id id, address account) external view returns (uint256) {
        return position[id][account].collateral;
    }

    // Returns the last update timestamp of the market for a given Id
    function lastUpdate(Id id) external view returns (uint256) {
        return market[id].lastUpdate;
    }

    // Returns the fee percentage for a given market Id
    function fee(Id id) external view returns (uint256) {
        return market[id].fee;
    }

    // Returns the virtual total supply assets for a given market Id
    function virtualTotalSupplyAssets(Id id) external view returns (uint256) {
        return market[id].totalSupplyAssets + SharesMathLib.VIRTUAL_ASSETS;
    }

    // Returns the virtual total supply shares for a given market Id
    function virtualTotalSupplyShares(Id id) external view returns (uint256) {
        return market[id].totalSupplyShares + SharesMathLib.VIRTUAL_SHARES;
    }

    // Returns the virtual total borrowed assets for a given market Id
    function virtualTotalBorrowAssets(Id id) external view returns (uint256) {
        return market[id].totalBorrowAssets + SharesMathLib.VIRTUAL_ASSETS;
    }

    // Returns the virtual total borrowed shares for a given market Id
    function virtualTotalBorrowShares(Id id) external view returns (uint256) {
        return market[id].totalBorrowShares + SharesMathLib.VIRTUAL_SHARES;
    }

    // Returns the library Id derived from MarketParams
    function libId(MarketParams memory marketParams) external pure returns (Id) {
        return marketParams.id();
    }

    // Returns a reference Id generated from MarketParams
    function refId(MarketParams memory marketParams) external pure returns (Id marketParamsId) {
        marketParamsId = Id.wrap(keccak256(abi.encode(marketParams)));
    }

    // Computes the result of x * y / d with rounding up
    function libMulDivUp(uint256 x, uint256 y, uint256 d) external pure returns (uint256) {
        return MathLib.mulDivUp(x, y, d);
    }

    // Computes the result of x * y / d with rounding down
    function libMulDivDown(uint256 x, uint256 y, uint256 d) external pure returns (uint256) {
        return MathLib.mulDivDown(x, y, d);
    }

    // Returns the minimum of x and y
    function libMin(uint256 x, uint256 y) external pure returns (uint256) {
        return UtilsLib.min(x, y);
    }

    // Checks if the given MarketParams and user address indicate a healthy state
    function isHealthy(MarketParams memory marketParams, address user) external view returns (bool) {
        return _isHealthy(marketParams, marketParams.id(), user);
    }
}
