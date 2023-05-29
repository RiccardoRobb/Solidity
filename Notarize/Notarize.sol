// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract Notarize is Ownable, AccessControlEnumerable {
    using Counters for Counters.Counter;

    bytes32 public constant HASH_WRITER = keccak256("HASH_WRITER");

    Counters.Counter private _docCounter;
    mapping(uint256 => Doc) private _documents;
    mapping(bytes32 => bool) private _regHashes;

    event DocHashAdded(uint256 indexed docCounter, string docUrl, bytes32 docHash);

    struct Doc {
        string docUrl;
        bytes32 docHash;
    }

    Counters.Counter public getInfoCounter;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setHashWriterRole(address _hashWriter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(HASH_WRITER, _hashWriter);
    }

    /**
    * @dev Store a new document structure
    * @param _url doc URL
    * @param _hash bytes32 Hash
    */
    function addNewDocument(string memory _url, bytes32 _hash) external onlyRole(HASH_WRITER) {
        require(!_regHashes[_hash], "Already notarized!");
        uint256 counter = _docCounter.current();

        _documents[counter] = Doc({docUrl: _url, docHash: _hash});
        _regHashes[_hash] = true;
        _docCounter.increment();

        emit DocHashAdded(counter, _url, _hash);
    }

    /**
    * @dev Get hash from num
    * @param _num uint256 position of hash to get
    * @return string documentURL, bytes32 hash, uint256 datetime
    */
    function getDocInfo(uint256 _num) external view returns (string memory, bytes32) {
        return (_documents[_num].docUrl, _documents[_num].docHash);
    }

    function getDocInfoAndCounter(uint256 _num) external returns (string memory, bytes32) {
        getInfoCounter.increment();
        return (_documents[_num].docUrl, _documents[_num].docHash);
    }

    function getDocsCount() external view returns (uint256) {
        return _docCounter.current();
    }

    function getRegisteredHash(uint256 _num) external view returns (bytes32 )
}