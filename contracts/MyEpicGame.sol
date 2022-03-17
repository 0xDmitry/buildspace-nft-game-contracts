// SPDX-License-Identifier: MIT

// Need to add: Customizable Mint (image, name), Rewards, Daily Boss, Leveling, Skills, Items, PvP

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

import "./libraries/Base64.sol";

contract MyEpicGame is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 private seed;

    struct CharacterAttributes {
        uint256 characterIndex;
        string name;
        string imageURI;
        uint256 hp;
        uint256 maxHp;
        uint256 attackDamage;
        uint256 critChance;
    }

    CharacterAttributes[] defaultCharacters;

    address[] public players;

    mapping(address => uint256) public addressToTokenId;
    mapping(uint256 => CharacterAttributes) public tokenIdToCharacterAttributes;
    mapping(uint256 => uint256) public tokenIdToDealedDamage;

    struct BigBoss {
        string name;
        string imageURI;
        uint256 hp;
        uint256 maxHp;
        uint256 attackDamage;
        uint256 attackChance;
    }

    BigBoss public bigBoss;

    event CharacterNFTMinted(
        address sender,
        uint256 tokenId,
        uint256 characterIndex
    );

    event AttackComplete(
        address sender,
        uint256 newBossHp,
        uint256 newCharacterHp,
        bool isCharacterCrited,
        bool isBossMissed
    );

    constructor(
        string[] memory characterNames,
        string[] memory characterImageURIs,
        uint256[] memory characterHp,
        uint256[] memory characterAttackDmg,
        uint256[] memory characterCritChance,
        string memory bossName,
        string memory bossImageURI,
        uint256 bossHp,
        uint256 bossAttackDamage,
        uint256 bossAttackChance
    ) ERC721("Heroes", "HERO") {
        bigBoss = BigBoss({
            name: bossName,
            imageURI: bossImageURI,
            hp: bossHp,
            maxHp: bossHp,
            attackDamage: bossAttackDamage,
            attackChance: bossAttackChance
        });

        console.log(
            "Done initializing boss %s w/ HP %s, img %s",
            bigBoss.name,
            bigBoss.hp,
            bigBoss.imageURI
        );

        for (uint256 i = 0; i < characterNames.length; i += 1) {
            defaultCharacters.push(
                CharacterAttributes({
                    characterIndex: i,
                    name: characterNames[i],
                    imageURI: characterImageURIs[i],
                    hp: characterHp[i],
                    maxHp: characterHp[i],
                    attackDamage: characterAttackDmg[i],
                    critChance: characterCritChance[i]
                })
            );

            CharacterAttributes memory c = defaultCharacters[i];
            console.log(
                "Done initializing %s w/ HP %s, img %s",
                c.name,
                c.hp,
                c.imageURI
            );
        }

        _tokenIds.increment();
        seed = (block.timestamp + block.difficulty) % 100;
    }

    function mintCharacterNFT(uint256 _characterIndex) external {
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);

        tokenIdToCharacterAttributes[newItemId] = CharacterAttributes({
            characterIndex: _characterIndex,
            name: defaultCharacters[_characterIndex].name,
            imageURI: defaultCharacters[_characterIndex].imageURI,
            hp: defaultCharacters[_characterIndex].hp,
            maxHp: defaultCharacters[_characterIndex].maxHp,
            attackDamage: defaultCharacters[_characterIndex].attackDamage,
            critChance: defaultCharacters[_characterIndex].critChance
        });

        console.log(
            "Minted NFT w/ tokenId %s and characterIndex %s",
            newItemId,
            _characterIndex
        );

        players.push(msg.sender);
        addressToTokenId[msg.sender] = newItemId;
        _tokenIds.increment();
        emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        CharacterAttributes
            memory characterAttributes = tokenIdToCharacterAttributes[_tokenId];

        string memory strHp = Strings.toString(characterAttributes.hp);
        string memory strMaxHp = Strings.toString(characterAttributes.maxHp);
        string memory strAttackDamage = Strings.toString(
            characterAttributes.attackDamage
        );
        string memory strCritChance = Strings.toString(
            characterAttributes.critChance
        );

        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                characterAttributes.name,
                " -- NFT #: ",
                Strings.toString(_tokenId),
                '", "description": "This is an NFT that lets people play in the game Metaverse Slayer!", "image": "ipfs://',
                characterAttributes.imageURI,
                '", "attributes": [ { "trait_type": "Health Points", "value": ',
                strHp,
                ', "max_value":',
                strMaxHp,
                '}, { "trait_type": "Attack Damage", "value": ',
                strAttackDamage,
                '}, { "trait_type": "Crit Chance", "value": ',
                strCritChance,
                "} ]}"
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function attackBoss() public {
        uint256 tokenId = addressToTokenId[msg.sender];
        CharacterAttributes storage character = tokenIdToCharacterAttributes[
            tokenId
        ];

        console.log(
            "\nPlayer w/ character %s about to attack. Has %s HP and %s AD",
            character.name,
            character.hp,
            character.attackDamage
        );
        console.log(
            "Boss %s has %s HP and %s AD",
            bigBoss.name,
            bigBoss.hp,
            bigBoss.attackDamage
        );

        require(
            character.hp > 0,
            "Error: character must have HP to attack boss."
        );
        require(
            bigBoss.hp > 0,
            "Error: boss must have HP to attack character."
        );

        seed = (block.difficulty + block.timestamp + seed) % 100;
        uint256 characterAttackDamage;
        bool isCharacterCrited;
        if (seed > character.critChance) {
            characterAttackDamage = character.attackDamage;
            isCharacterCrited = false;
        } else {
            characterAttackDamage = character.attackDamage * 2;
            isCharacterCrited = true;
        }

        if (bigBoss.hp < characterAttackDamage) {
            bigBoss.hp = 0;
            tokenIdToDealedDamage[tokenId] += bigBoss.hp;
        } else {
            bigBoss.hp -= characterAttackDamage;
            tokenIdToDealedDamage[tokenId] += characterAttackDamage;
        }

        seed = (block.difficulty + block.timestamp + seed) % 100;
        uint256 bigBossAttackDamage;
        bool isBossMissed;
        if (seed > bigBoss.attackChance) {
            bigBossAttackDamage = 0;
            isBossMissed = true;
        } else {
            bigBossAttackDamage = bigBoss.attackDamage;
            isBossMissed = false;
        }

        if (character.hp < bigBossAttackDamage) {
            character.hp = 0;
        } else {
            character.hp -= bigBossAttackDamage;
        }

        console.log(
            "Player's character attacked the boss. New boss hp: %s",
            bigBoss.hp
        );
        console.log(
            "Boss attacked player's character. New character hp: %s\n",
            character.hp
        );

        emit AttackComplete(
            msg.sender,
            bigBoss.hp,
            character.hp,
            isCharacterCrited,
            isBossMissed
        );
    }

    function checkIfUserHasNFT()
        public
        view
        returns (CharacterAttributes memory)
    {
        uint256 tokenId = addressToTokenId[msg.sender];
        if (tokenId > 0) {
            return tokenIdToCharacterAttributes[tokenId];
        } else {
            CharacterAttributes memory emptyStruct;
            return emptyStruct;
        }
    }

    function getAllDefaultCharacters()
        public
        view
        returns (CharacterAttributes[] memory)
    {
        return defaultCharacters;
    }

    struct PlayerInfo {
        address playerAddress;
        CharacterAttributes characterAttributes;
        uint256 dealedDamage;
    }

    function getAllPlayers() public view returns (PlayerInfo[] memory) {
        PlayerInfo[] memory result = new PlayerInfo[](players.length);

        for (uint256 i = 0; i < players.length; i++) {
            address playerAddress = players[i];
            uint256 tokenId = addressToTokenId[playerAddress];

            result[i] = PlayerInfo(
                playerAddress,
                tokenIdToCharacterAttributes[tokenId],
                tokenIdToDealedDamage[tokenId]
            );
        }

        return result;
    }
}
