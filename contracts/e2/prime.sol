// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract PrimeNumberChecker {
    function isPrime(uint number) public pure returns (string memory) {
        if (number <= 1) {
            return "Number is not prime";
        }

        // loop to check factors
        for (uint i = 2; i * i <= number; i++) {
            if (number % i == 0) {
                return "Number is not prime";
            }
        }
        return "Number is prime";
    }
}
