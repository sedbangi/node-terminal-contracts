// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ERC721Enumerable,
contract OrbiterNodes is Ownable, ERC721Burnable, Pausable, AccessControl {
    modifier onlySellContract() {
        require(msg.sender == nodeSellContract, "OBN: Only sell contract");
        _;
    }

    event SkipIds(uint256 indexed startId, uint256 indexed endId);

    mapping(uint256 => uint256) public skipIds;

    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    uint256 private _tokenIdTracker;

    uint256 public maxSupply;

    string public baseTokenURI;

    address public nodeSellContract;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _inputbaseURI,
        address _owner,
        address[] memory _governors,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) Ownable(_owner) {
        require(_owner != address(0), "OBN: Invalid owner");

        require(_maxSupply > 0, "OBN: Max supply must be greater than 0");
        setBaseURI(_inputbaseURI);
        maxSupply = _maxSupply;

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);

        for (uint256 i = 0; i < _governors.length; i++) {
            _grantRole(GOVERNOR_ROLE, _governors[i]);
        }

        _pause();
    }

    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker;
    }
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }
    function mint(address _to) public onlySellContract returns (uint256) {
        return _mintAnElement(_to);
    }

    function _mintAnElement(address _to) private returns (uint256 id) {
        id = _totalSupply();
        require(id < maxSupply, "OBN: Max supply reached");
        _handleIdTracker();
        _safeMint(_to, id);
    }

    function _handleIdTracker() internal {
        uint256 skipId = skipIds[_tokenIdTracker];
        skipId != 0 ? (_tokenIdTracker = skipId) : (_tokenIdTracker++);
    }

    function transferfrom(
        address from,
        address _to,
        uint256 _tokenId
    ) public whenNotPaused {
        _safeTransfer(from, _to, _tokenId);
    }

    /***governance */
    function transferOwnership(address newOwner) public override onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
    }

    function setSkipIds(
        uint256[] calldata _idStart,
        uint256[] calldata _idEnd
    ) external onlyRole(GOVERNOR_ROLE) {
        require(_idStart.length == _idEnd.length, "OBN: Invalid length");
        uint256 currentId = _tokenIdTracker;
        for (uint256 i = 0; i < _idEnd.length; i++) {
            require(_idStart[i] < _idEnd[i], "OBN: Invalid id range");
            require(_idStart[i] > currentId, "OBN: Invalid id");
            skipIds[_idStart[i]] = _idEnd[i];
            emit SkipIds(_idStart[i], _idEnd[i]);
        }
    }

    function pause(bool _paused) external onlyRole(GOVERNOR_ROLE) {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setNodeSellContract(
        address _inputnodeSellContract
    ) external onlyRole(GOVERNOR_ROLE) {
        require(
            _inputnodeSellContract != address(0),
            "OBN: Invalid sell contract"
        );
        nodeSellContract = _inputnodeSellContract;
    }

    function setNewMaxSupply(
        uint256 _maxSupply
    ) external onlyRole(GOVERNOR_ROLE) {
        require(_maxSupply > 0, "OBN: Max supply must be greater than 0");
        maxSupply = _maxSupply - 1;
    }

    function initialize(address _inputnodeSellContract) external {
        require(
            _inputnodeSellContract != address(0),
            "OBN: Invalid sell contract"
        );

        require(nodeSellContract == address(0), "OBN: Already initialized");

        nodeSellContract = _inputnodeSellContract;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // The following functions are overrides required by Solidity.
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
