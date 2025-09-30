// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./@reactive.network/contracts/Reactive.sol";
import "./RarityTracker.sol";
contract ReactiveRarityUpdater is Reactive {
    address public originNftAddress;
    address public destinationTrackerAddress;
    constructor(
        address _reactiveService,
        address _originNftAddress,
        address _destinationTrackerAddress
    ) Reactive(_reactiveService) {
        originNftAddress = _originNftAddress;
        destinationTrackerAddress = _destinationTrackerAddress;
    }
    function subscribeToMintEvents() external {
        bytes32 eventSignature = keccak256(
            "Transfer(address,address,uint256)"
        );
        bytes32 fromTopic = bytes32(uint256(uint160(address(0))));
        subscribe(originNftAddress, eventSignature, fromTopic);
    }
    function onEvent(
        uint256,
        address,
        bytes calldata log
    ) external override onlyReactiveService {
        (uint256 tokenId) = abi.decode(log, (uint256));
        RarityTracker.Trait[] memory mockTraits = _getMockTraits(tokenId);
        bytes memory callbackData = abi.encode(tokenId, mockTraits);
        reactiveService.callback(destinationTrackerAddress, callbackData);
    }
    function _getMockTraits(
        uint256 tokenId
    ) internal pure returns (RarityTracker.Trait[] memory) {
        RarityTracker.Trait[] memory traits = new RarityTracker.Trait[](3);
        if (tokenId % 2 == 0) {
            traits[0] = RarityTracker.Trait("Background", "Blue");
            traits[1] = RarityTracker.Trait("Eyes", "Happy");
            traits[2] = RarityTracker.Trait("Mouth", "Smile");
        } else {
            traits[0] = RarityTracker.Trait("Background", "Red");
            traits[1] = RarityTracker.Trait("Eyes", "Sad");
            traits[2] = RarityTracker.Trait("Mouth", "Frown");
        }
        return traits;
    }
}