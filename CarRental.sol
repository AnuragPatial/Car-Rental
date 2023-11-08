// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CarRental {
    address public owner;
    IERC20 public token;
    uint256 public rentalPrice;
    address public currentRenter;
    uint256 public rentalEndTime;

    event CarRented(address indexed renter, uint256 endTime);
    event CarReturned();

    constructor(address _tokenAddress, uint256 _initialRentalPrice) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
        rentalPrice = _initialRentalPrice;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function setRentalPrice(uint256 _newPrice) public onlyOwner {
        rentalPrice = _newPrice;
    }

    function rentCar(uint256 _rentalDuration) public {
        require(_rentalDuration > 0, "Rental duration must be greater than 0");
        require(token.balanceOf(msg.sender) >= rentalPrice * _rentalDuration, "Insufficient balance to rent the car");

        if (currentRenter != address(0)) {
            require(msg.sender == currentRenter, "The car is already rented by someone else");
            rentalEndTime += _rentalDuration;
        } else {
            currentRenter = msg.sender;
            rentalEndTime = block.timestamp + _rentalDuration;
        }

        token.transferFrom(msg.sender, address(this), rentalPrice * _rentalDuration);
        emit CarRented(msg.sender, rentalEndTime);
    }

    function returnCar() public {
        require(msg.sender == currentRenter, "You can't return a car you haven't rented");
        require(block.timestamp >= rentalEndTime, "The rental period is not over yet");

        uint256 rentalDuration = (block.timestamp - rentalEndTime);
        uint256 refundAmount = rentalPrice * (rentalDuration / 1 days); // Refund one day's worth of rent for each day not used

        token.transfer(currentRenter, refundAmount);

        currentRenter = address(0);
        rentalEndTime = 0;

        emit CarReturned();
    }
}
