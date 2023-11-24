// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.7;

contract FlappyBeeGame {
    struct Record {
        uint256 dateTime;
        uint256 score;
        address walletAddress;
    }

    Record[] public records;

    function addRecord(
        uint256 _dateTime,
        uint256 _score,
        address _walletAddress
    ) public {
        Record memory newRecord = Record({
            dateTime: _dateTime,
            score: _score,
            walletAddress: _walletAddress
        });

        records.push(newRecord);
    }

    function getRecordsCount() public view returns (uint256) {
        return records.length;
    }

    function findRecordsByWalletAddress(
        address _walletAddress
    ) public view returns (Record[] memory) {
        uint matchCount = 0;
        for (uint256 i = 0; i < records.length; i++) {
            if (records[i].walletAddress == _walletAddress) {
                matchCount += 1;
            }
        }

        Record[] memory matchingRecords = new Record[](matchCount);

        uint matchId = 0;
        for (uint256 i = 0; i < records.length; i++) {
            if (records[i].walletAddress == _walletAddress) {
                matchingRecords[matchId] = records[i];
                matchId += 1;
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
