// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract ArraySearch {
    uint[] public numbers;

    // Function to store array elements
    function setArray(uint[] memory _numbers) public {
        delete numbers; // clear old data
        for (uint i = 0; i < _numbers.length; i++) {
            numbers.push(_numbers[i]);
        }
    }

    // Function to search target value
    function searchValue(uint target) public view returns (string memory) {
        for (uint i = 0; i < numbers.length; i++) {
            if (numbers[i] == target) {
                return string(abi.encodePacked("Value found at index: ", uint2str(i)));
            }
        }
        return "Value not found";
    }

    // Helper function: uint to string conversion
    function uint2str(uint _i) internal pure returns (string memory str) {
        if (_i == 0) return "0";
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        j = _i;
        while (j != 0) {
            k = k - 1;
            uint8 temp = uint8(48 + j % 10);
            bstr[k] = bytes1(temp);
            j /= 10;
        }
        str = string(bstr);
    }
}
