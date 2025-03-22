// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LendingPool is Ownable {
    struct Loan {
        uint256 invoiceId;
        address borrower;
        address lender;
        uint256 amount;
        uint256 repaidAmount;
        bool isRepaid;
    }

    InvoiceToken public invoiceToken;
    ReputationManager public reputationManager;
    address public defaultOracle;
    uint256 public nextLoanId;
    uint256 public constant MIN_PAYMENT = 0.01 ether;
    bool public paused;

    mapping(uint256 => Loan) public loans;
    mapping(address => uint256) public withdrawableBalance;

    event LoanFunded(uint256 loanId, address lender, address borrower, uint256 amount);
    event LoanRepaid(uint256 loanId, address borrower, uint256 amount);
    event LoanFullyRepaid(uint256 loanId);
    event LoanDefaulted(uint256 loanId, address borrower);
    event LoanLiquidated(uint256 loanId);
    event Withdrawn(address indexed lender, uint256 amount);
    event Paused();
    event Unpaused();

    modifier onlyOracleOrOwner() {
        require(msg.sender == defaultOracle || msg.sender == owner(), "Not authorized");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(address _invoiceToken, address _reputationManager) {
        invoiceToken = InvoiceToken(_invoiceToken);
        reputationManager = ReputationManager(_reputationManager);
    }

    function calculateInterest(uint256 invoiceId, uint256 principal) public view returns (uint256) {
        InvoiceToken.InvoiceData memory data = invoiceToken.getInvoice(invoiceId);
        uint256 baseInterest = (principal * data.interestRate) / 10000;
        if (block.timestamp <= data.dueDate) {
            return baseInterest;
        } else {
            uint256 daysLate = (block.timestamp - data.dueDate) / 1 days;
            uint256 penalty = (principal * daysLate) / 100;
            return baseInterest + penalty;
        }
    }

    // rest of LendingPool remains unchanged
    // (functions like fundInvoice, repayLoan, withdraw, etc.)
}
