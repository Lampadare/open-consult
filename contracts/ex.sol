// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract IterableMapping {
    struct Entry {
        uint value;
        uint index;  // index in the keys array
    }

    mapping(address => Entry) public entries;
    address[] public keys;

    function set(address _key, uint _value) public {
        if (entries[_key].index > 0) {
            // Entry already exists, update value
            entries[_key].value = _value;
        } else {
            // New entry, add to keys array
            keys.push(_key);
            entries[_key] = Entry(_value, keys.length - 1);
        }
    }

    function remove(address _key) public {
        require(entries[_key].index > 0, "Entry does not exist");

        // Move the last key into the place of the key to delete
        uint indexToDelete = entries[_key].index;
        address keyToMove = keys[keys.length - 1];
        keys[indexToDelete] = keyToMove;

        // Update the moved entry's index
        entries[keyToMove].index = indexToDelete;
        keys.pop();

        // Delete the entry from the mapping
        delete entries[_key];
    }
    
    function getKeys() public view returns(address[] memory) {
        return keys;
    }
}
