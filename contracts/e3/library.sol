// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract LibrarySystem {
    struct Book {
        uint id;
        string title;
        string author;
        bool isAvailable;
        address borrower;
    }

    address public admin;
    uint private nextBookId = 1;
    mapping(uint => Book) private books;
    uint[] private bookIds;

    event BookAdded(uint indexed bookId, string title, string author);
    event BookBorrowed(uint indexed bookId, address indexed borrower);
    event BookReturned(uint indexed bookId, address indexed borrower);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Add a new book (admin only)
    function addBook(string memory title, string memory author) external onlyAdmin {
        books[nextBookId] = Book({
            id: nextBookId,
            title: title,
            author: author,
            isAvailable: true,
            borrower: address(0)
        });
        bookIds.push(nextBookId);
        emit BookAdded(nextBookId, title, author);
        nextBookId++;
    }

    // Borrow a book
    function borrowBook(uint bookId) external {
        Book storage b = books[bookId];
        require(b.id != 0, "Book does not exist");
        require(b.isAvailable, "Book not available");
        b.isAvailable = false;
        b.borrower = msg.sender;
        emit BookBorrowed(bookId, msg.sender);
    }

    // Return a book
    function returnBook(uint bookId) external {
        Book storage b = books[bookId];
        require(b.id != 0, "Book does not exist");
        require(b.borrower == msg.sender, "You did not borrow this book");
        b.isAvailable = true;
        b.borrower = address(0);
        emit BookReturned(bookId, msg.sender);
    }

    // Get book details
    function getBook(uint bookId) external view returns (uint, string memory, string memory, bool, address) {
        Book storage b = books[bookId];
        require(b.id != 0, "Book does not exist");
        return (b.id, b.title, b.author, b.isAvailable, b.borrower);
    }

    // Get total number of books
    function totalBooks() external view returns (uint) {
        return bookIds.length;
    }

    // Get all book IDs
    function getAllBookIds() external view returns (uint[] memory) {
        return bookIds;
    }
}
