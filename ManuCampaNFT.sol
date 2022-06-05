// // SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";

contract ManuCampaNFT is Ownable, ERC1155, ERC1155Supply, ERC1155Pausable {
    using Strings for uint256;

    uint256 public constant THE_PASSION = 0;
    uint256 public constant THE_GARAGE = 1;
    uint256 public constant THE_DRIVING = 2;
    uint256 public constant THE_ENGINE = 3;
    uint256 public constant THE_PIT_STOP = 4;
    uint256 public constant THE_HODL_IN_THE_TUNNEL = 5;
    uint256 public constant THE_DEVIL = 6;

    string[] public TITLES = [
        "The passion",
        "The garage",
        "The driving",
        "The engine",
        "The pit stop",
        "Hodl in the tunnel",
        "The devil"
    ];

    constructor(
        address _owner,
        address _marketingWallet,
        string memory _uri
    ) ERC1155(_uri) {
        _mint(_owner, THE_PASSION, 3, "0x0");
        _mint(_owner, THE_GARAGE, 3, "0x0");
        _mint(_owner, THE_DRIVING, 6, "0x0");
        _mint(_owner, THE_ENGINE, 6, "0x0");
        _mint(_owner, THE_PIT_STOP, 8, "0x0");
        _mint(_owner, THE_HODL_IN_THE_TUNNEL, 8, "0x0");
        _mint(_owner, THE_DEVIL, 22, "0x0");

        _mint(_marketingWallet, THE_PIT_STOP, 1, "0x0");
        _mint(_marketingWallet, THE_HODL_IN_THE_TUNNEL, 1, "0x0");
        _mint(_marketingWallet, THE_DEVIL, 2, "0x0");

        _setURI(_uri);
        transferOwnership(_owner);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setURI(string memory newuri) public {
        _setURI(newuri);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    super.uri(tokenId),
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
