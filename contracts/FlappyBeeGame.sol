// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.7;

contract FlappyBeeGame {
    struct Record {
        uint256 date;
        uint256 time;
        uint256 score;
        address walletAddress;
    }

    Record[] public records;

    function addRecord(uint256 _date, uint256 _time, uint256 _score, address _walletAddress) public {
        Record memory newRecord = Record({
            date: _date,
            time: _time,
            score: _score,
            walletAddress: _walletAddress
        });

        records.push(newRecord);
    }

    function getRecordsCount() public view returns (uint256) {
        return records.length;
    }

    function findRecordsByWalletAddress(address _walletAddress) public view returns (Record[] memory) {
        Record[] memory matchingRecords;

        for (uint256 i = 0; i < records.length; i++) {
            if (records[i].walletAddress == _walletAddress) {
                matchingRecords.push(records[i]);
            }
        }

        return matchingRecords;
    }

    function removeRecordsByWalletAddress(address _walletAddress) public {
        for (uint256 i = records.length - 1; i >= 0; i--) {
            if (records[i].walletAddress == _walletAddress) {
                // Remove the record at index i by swapping it with the last record in the array
                records[i] = records[records.length - 1];
                records.pop();
            }
        }
    }
}
