// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract A {
    uint internal a;

    function setA(uint _a) public {
        a = _a;
    }

    function getA() public view returns (uint) {
        return a;
    }
}

contract B {
    uint internal b;

    function setB(uint _b) public {
        b = _b;
    }

    function getB() public view returns (uint) {
        return b;
    }
}

contract C is A, B {
    function sum() public view returns (uint) {
        return a + b;
    }
}

contract Caller {
    C private cInstance;

    constructor() {
        cInstance = new C();
    }

    // Set values in contract C (through inherited functions)
    function setValues(uint _a, uint _b) public {
        cInstance.setA(_a);
        cInstance.setB(_b);
    }

    function getValueA() public view returns (uint) {
        return cInstance.getA();
    }

    function getValueB() public view returns (uint) {
        return cInstance.getB();
    }

    function getSum() public view returns (uint) {
        return cInstance.sum();
    }

    function getDeployedCAddress() public view returns (address) {
        return address(cInstance);
    }
}
