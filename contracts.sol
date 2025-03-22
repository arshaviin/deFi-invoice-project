// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract InvoiceToken is ERC721URIStorage {
    uint256 public nextTokenId;

    struct InvoiceData {
        uint256 amount;
        address issuer;
        address debtor;
        uint256 dueDate;
        bool isPaid;
        uint256 interestRate; // basis points (e.g., 1000 = 10%)
    }

    mapping(uint256 => InvoiceData) public invoices;
    mapping(uint256 => address) public invoiceOwner;
    address public lendingPool;

    modifier onlyIssuer(uint256 tokenId) {
        require(msg.sender == invoices[tokenId].issuer, "Not the issuer");
        _;
    }

    modifier onlyAuthorized(uint256 tokenId) {
        require(
            msg.sender == invoices[tokenId].issuer || msg.sender == lendingPool,
            "Not authorized"
        );
        _;
    }

    constructor() ERC721("InvoiceToken", "INV") {}

    function setLendingPool(address _pool) external {
        require(lendingPool == address(0), "Already set");
        lendingPool = _pool;
    }

    function mint(
        string memory tokenURI,
        uint256 amount,
        address debtor,
        uint256 dueDate,
        uint256 interestRate // basis points (e.g., 1000 = 10%)
    ) external returns (uint256) {
        uint256 tokenId = nextTokenId++;
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);

        invoices[tokenId] = InvoiceData({
            amount: amount,
            issuer: msg.sender,
            debtor: debtor,
            dueDate: dueDate,
            isPaid: false,
            interestRate: interestRate
        });

        invoiceOwner[tokenId] = msg.sender;

        return tokenId;
    }

    function markAsPaid(uint256 tokenId) external onlyAuthorized(tokenId) {
        invoices[tokenId].isPaid = true;
    }

    function getInvoice(uint256 tokenId) external view returns (InvoiceData memory) {
        return invoices[tokenId];
    }
}

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

contract ReputationManager is Ownable {
    mapping(address => uint256) public score;

    event ScoreUpdated(address indexed user, uint256 score);

    function setScore(address user, uint256 newScore) external onlyOwner {
        score[user] = newScore;
        emit ScoreUpdated(user, newScore);
    }

    function adjustScore(address user, int256 delta) external onlyOwner {
        uint256 current = score[user];
        if (delta < 0 && current < uint256(-delta)) {
            score[user] = 0;
        } else {
            score[user] = uint256(int256(current) + delta);
        }
        emit ScoreUpdated(user, score[user]);
    }

    function getScore(address user) external view returns (uint256) {
        return score[user];
    }
}
