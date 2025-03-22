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