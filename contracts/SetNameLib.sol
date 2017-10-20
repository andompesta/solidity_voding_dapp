pragma solidity ^0.4.11;


library SetNameLib {

    struct Data {
    mapping(bytes32 => IndexValue) flags;
    KeyFlag[] keys;
    uint size;
    }

    struct IndexValue {
    uint keyIndex;
    bool value;
    }

    struct KeyFlag {
    bytes32 key;
    bool deleted;
    }

    function insert(Data storage self, bytes32 key, bool value) public returns (bool replaced)
    {
        uint keyIndex = self.flags[key].keyIndex;
        self.flags[key].value = value;
        if (keyIndex > 0)
        return true;
        else {
            keyIndex = self.keys.length++;
            self.flags[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
            return false;
        }
    }

    function remove(Data storage self, bytes32 key) public returns (bool success)
    {
        uint keyIndex = self.flags[key].keyIndex;
        if (keyIndex == 0)
        return false;
        delete self.flags[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size --;
    }

    function contains(Data storage self, bytes32 key) public returns (bool) {
        return self.flags[key].keyIndex > 0;
    }

    function iterate_start(Data storage self) public  returns (uint keyIndex)
    {
        return iterate_next(self, uint(-1));
    }

    function iterate_valid(Data storage self, uint keyIndex) public  returns (bool)
    {
        return keyIndex < self.keys.length;
    }

    function iterate_next(Data storage self, uint keyIndex) public  returns (uint r_keyIndex)
    {
        keyIndex++;
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
        keyIndex++;
        return keyIndex;
    }

    function iterate_get(Data storage self, uint keyIndex) public  returns (bytes32 key, bool value)
    {
        key = self.keys[keyIndex].key;
        value = self.flags[key].value;
    }

    function get_index(Data storage self, bytes32 key) public  returns (uint keyIndex)
    {
        keyIndex = self.flags[key].keyIndex;
    }
}


