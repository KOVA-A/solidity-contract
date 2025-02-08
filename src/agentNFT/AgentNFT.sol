// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC6551Registry} from "erc6551-reference/ERC6551Registry.sol";
import {IERC6551Registry} from "erc6551-reference/interfaces/ERC6551Registry.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC7662} from "src/interfaces/IERC7662.sol";
import "src/libraries/constants/Types.sol";

contract AgentNFT is Ownable, ERC721, ERC721Enumerable, ERC721URIStorage, IERC7662 {
    address private agentRoom;
    address private constant ERC6551RegistryAddress = 0x000000006551c19487814612e58FE06813775758;
    address private constant ERC6551AccountProxyAddress = 0x55266d75D1a14E4572138116aF39863Ed6596E7F;
    mapping(uint256 => AgentData) public agentData;

    constructor(address initialOwner) ERC721("AgentNFT", "KOVA") Ownable(initialOwner) {}

    function setAgentRoom(address _agentRoom) external onlyOwner {
        agentRoom = _agentRoom;
    }

    function mint(AgentData memory _agentData) external returns (address tbaAddress) {
        uint256 currentTokenId = totalSupply() + 1;
        _mint(msg.sender, currentTokenId);
        agentData[currentTokenId] = _agentData;
        _setTokenURI(currentTokenId, _agentData.systemPromptURI);
        approve(agentRoom, currentTokenId);
        tbaAddress = IERC6551Registry(ERC6551RegistryAddress).createAccount(
            ERC6551AccountProxyAddress, bytes32(currentTokenId), block.chainid, address(this), currentTokenId
        );
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        address previousOwner = ERC721Enumerable._update(to, tokenId, auth);
        return previousOwner;
    }

    function _increaseBalance(address account, uint128 amount) internal virtual override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._increaseBalance(account, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC721URIStorage, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC7662).interfaceId || interfaceId == type(IERC165).interfaceId
            || ERC721.supportsInterface(interfaceId) || ERC721Enumerable.supportsInterface(interfaceId)
            || ERC721URIStorage.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function getAgentData(uint256 tokenId)
        external
        view
        override
        returns (
            string memory name,
            string memory description,
            string memory model,
            string memory userPromptURI,
            string memory systemPromptURI,
            bool promptsEncrypted
        )
    {
        AgentData memory agentData_ = agentData[tokenId];
        return (
            agentData_.name,
            agentData_.description,
            agentData_.model,
            agentData_.userPromptURI,
            agentData_.systemPromptURI,
            agentData_.promptsEncrypted
        );
    }

    function getAgentExtraData(uint256 agentId)
        external
        view
        returns (AgentType agentType, RiskLevel riskLevel, uint256 investmentAmount, address[] memory preferredAssets)
    {
        agentType = agentData[agentId].agentType;
        riskLevel = agentData[agentId].riskLevel;
        investmentAmount = agentData[agentId].investmentAmount;
        preferredAssets = agentData[agentId].preferredAssets;
    }
}
