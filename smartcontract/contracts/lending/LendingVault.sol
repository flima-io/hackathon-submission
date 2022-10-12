// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";
enum Status {
    initial,
    nftDeposited,
    canceled,
    loan,
    repayed,
    liquidated
}
struct Loan {
    // nonzero means staus is already setup for the address
    address contractAddress;
    address borrower;
    // lender address => bool
    mapping(address => bool) canWithdraw;
    Status status;
}

/**
 * A contract that holds users assets related to lending.
 * Instead of holding asset of each lending in the Lending contract, we store all the assets in a single Vault.
 * The reason is simply to reduce the number of Approve transaction. With this design, user just needs to approve Vault once.
 */
contract LendingVault is Ownable, IERC721Receiver {
    address private constant FLIMA = 0xD89fBf940A5F7D2B07Dc2fA08229bB7791C8C33e;

    mapping(address => Loan) private loans;

    address private factoryAddress;

    function setFactoryAddress(address _factoryAddress) external onlyOwner {
        factoryAddress = _factoryAddress;
    }

    function addNewLending(address lendingContractAddress, address borrower)
        external
        onlyFactory
    {
        // we can't set zero address
        require(lendingContractAddress != address(0), "E-3509cda7b");
        Loan storage loan = loans[lendingContractAddress];
        // this can be set only once
        require(loan.contractAddress == address(0), "E-3509cd807");
        loan.contractAddress = lendingContractAddress;
        loan.borrower = borrower;
        loan.status = Status.initial;
    }

    function depositCollateralNFT(
        address lendingContractAddress,
        address _collateral,
        uint256 _tokenId
    ) external onlyFactory {
        Loan storage loan = loans[lendingContractAddress];
        require(loan.status == Status.initial, "E-3505d483d");
        loan.status = Status.nftDeposited;
        // needs approve before this
        IERC721(_collateral).safeTransferFrom(
            loan.borrower,
            address(this),
            _tokenId
        );
    }

    function cancel(
        address originator,
        address _collateral,
        uint256 _tokenId
    ) external onlyBorrower(originator) {
        Loan storage loan = loans[msg.sender];
        require(loan.status == Status.nftDeposited, "E-35023708f");
        loan.status = Status.canceled;

        IERC721(_collateral).safeTransferFrom(
            address(this),
            loan.borrower,
            _tokenId
        );
    }

    function depositLoan(
        address lender,
        address _currency,
        uint256 _amount
    ) external onlyContract {
        require(!loans[msg.sender].canWithdraw[lender], "E-3509f4f1b");
        loans[msg.sender].canWithdraw[lender] = true;

        IERC20(_currency).transferFrom(lender, address(this), _amount);
    }

    function withdrawLoan(
        address _lender,
        address _currency,
        uint256 _amount
    ) external onlyContract {
        require(loans[msg.sender].canWithdraw[_lender], "E-3509ef1a3");
        loans[msg.sender].canWithdraw[_lender] = false;

        // send back money from contract to lender
        IERC20(_currency).approve(address(this), _amount);
        IERC20(_currency).transferFrom(address(this), _lender, _amount);
    }

    function startLoan(
        address _borrower,
        address _lender,
        address _currency,
        uint256 _amount
    ) external onlyContract {
        Loan storage loan = loans[msg.sender];
        require(loan.status == Status.nftDeposited, "E-350a9708f");
        require(loan.canWithdraw[_lender], "E-350a97a86");
        loan.status = Status.loan;
        loan.canWithdraw[_lender] = false;
        // send money to borrower. NFT is still kept in the vault
        IERC20(_currency).approve(address(this), _amount);
        IERC20(_currency).transferFrom(address(this), _borrower, _amount);
    }

    function repay(
        address originator,
        address currency,
        address lender,
        uint256 repayAmount,
        uint256 fee,
        address collateral,
        uint256 tokenId
    ) external onlyBorrower(originator) {
        Loan storage loan = loans[msg.sender];
        require(loan.status == Status.loan, "E-35066f285");
        loan.status = Status.repayed;

        IERC721(collateral).safeTransferFrom(
            address(this),
            loan.borrower,
            tokenId
        );
        if (fee > 0) {
            IERC20(currency).transferFrom(loan.borrower, FLIMA, fee);
        }
        // before this function runs, borrower needs to approve
        // send money back to lender
        IERC20(currency).transferFrom(loan.borrower, lender, repayAmount - fee);
    }

    function liquidate(
        address _lender,
        address _collateral,
        uint256 _tokenId
    ) external {
        Loan storage loan = loans[msg.sender];
        require(loan.status == Status.loan, "E-350bcd285");
        loan.status = Status.liquidated;

        IERC721(_collateral).safeTransferFrom(address(this), _lender, _tokenId);
    }

    /*******************
     * modifiers
     ********************/
    modifier onlyContract() {
        Loan storage st = loans[msg.sender];
        require(st.contractAddress == msg.sender, "E-350d27e99");
        _;
    }

    modifier onlyBorrower(address originator) {
        Loan storage st = loans[msg.sender];
        require(st.contractAddress == msg.sender, "E-350dc7e99");
        require(originator == st.borrower, "E-350dc7e5b");
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factoryAddress, "E-35092203d");
        _;
    }

    /**
     * Necessary to hold NFT. See IERC721Receiver.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
