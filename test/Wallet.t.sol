// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console, Vm} from "forge-std/Test.sol";
import {WalletFactory} from "../contracts/WalletFactory.sol";
import {Wallet} from "../contracts/Wallet.sol";
import {ControllerRegistry} from "../contracts/ControllerRegistry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IWallet} from "../contracts/interfaces/IWallet.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {
        _mint(msg.sender, 1000000 * 10**decimals());
    }
}

contract MockERC721 is ERC721 {
    uint256 private _tokenIdCounter;

    constructor() ERC721("Mock NFT", "MNFT") {
        _mint(msg.sender, 1);
        _tokenIdCounter = 1;
    }

    function mint(address to) public {
        _tokenIdCounter++;
        _mint(to, _tokenIdCounter);
    }
}

contract MockExternalContract {
    IERC20 public token;
    
    constructor(address _token) {
        token = IERC20(_token);
    }
    
    function receiveTokens(uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }
}

contract WalletTest is Test {
    Wallet public walletImplementation;
    WalletFactory public factory;
    ControllerRegistry public controllerRegistry;
    MockERC20 public token;
    // MockERC721 public nft;
    MockExternalContract public externalContract;
    IWallet public wallet; // This will be a clone
    
    address public owner; //owner of the contracts
    address public user1; //test user
    address public user2; //test user
    address public controller1; //test controller

    bytes32 public constant TOKEN_OPERATIONS = keccak256("TOKEN_OPERATIONS");

    function setUp() public {
      owner = address(this);
      user1 = payable(makeAddr("user1"));
      controller1 = makeAddr("controller1");

      // Deploy infrastructure
      controllerRegistry = new ControllerRegistry();
      walletImplementation = new Wallet();
      factory = new WalletFactory(address(walletImplementation), address(controllerRegistry));
      
      // Deploy test tokens
      token = new MockERC20();
      // nft = new MockERC721();
      externalContract = new MockExternalContract(address(token));

      // Register controller in registry
      controllerRegistry.registerController(
          controller1, 
          "TOKEN_OPERATIONS", 
          "Token Operations", 
          "1.0", 
          "Token operations permission"
      );

      // Setup initial balances
      vm.deal(address(user1), 100 ether);
      token.transfer(address(user1), 1000 * 10**token.decimals());
      // nft.mint(address(wallet));

      // Deploy wallet clone for user1
      vm.startPrank(user1);
      wallet = IWallet(factory.createWallet());
      vm.stopPrank();
    }

    function testUserDepositNativeBERAToWallet() public {
      uint256 initialBalance = address(user1).balance;
      uint256 depositAmount = 1 ether;

      // Deposit BERA using user1
      vm.startPrank(user1);
      (bool success,) = address(wallet).call{value: depositAmount}("");
      require(success, "Transfer failed");
      vm.stopPrank();

      assertEq(address(user1).balance, initialBalance - depositAmount);
      assertEq(address(wallet).balance, depositAmount);
    }

    function testUserWithdrawNativeBERAToWallet() public {
      uint256 initialBalance = address(user1).balance;
      uint256 withdrawAmount = 1 ether;

      vm.deal(address(wallet), withdrawAmount);

      // Withdraw BERA using user1
      vm.startPrank(user1);
      wallet.ownerExecute(user1, withdrawAmount, "");
      vm.stopPrank();

      assertEq(address(user1).balance, initialBalance + withdrawAmount);
      assertEq(address(wallet).balance, 0);
    }

    function testRevertIfUnauthorizedUserWithdrawsBERA() public {
      uint256 withdrawAmount = 1 ether;

      vm.deal(address(wallet), withdrawAmount);

      // Withdraw BERA using user1
      vm.startPrank(user2);
      vm.expectRevert("Not owner");
      wallet.ownerExecute(user2, withdrawAmount, "");
      vm.stopPrank();

      // Verify wallet balance hasn't changed
      assertEq(address(wallet).balance, withdrawAmount);
    }
    

    // function testTransferNativeETH() public {
    //   uint256 initialBalance = address(user1).balance;
    //   uint256 transferAmount = 1 ether;
      
    //   // Transfer BERA using owner
    //   wallet.ownerExecute(user1, transferAmount, "");
    //   assertEq(address(user1).balance, initialBalance + transferAmount);
      
    //   // Transfer BERA using controller with permission
    //   vm.startPrank(user1);
    //   wallet.controllerExecute(user2, transferAmount, "", TOKEN_OPERATIONS);
    //   vm.stopPrank();
      
    //   assertEq(address(user2).balance, transferAmount);
    // }

    // function testControllerOperations() public {
    //     uint256 transferAmount = 100 * 10**token.decimals();
        
    //     bytes memory transferData = abi.encodeWithSelector(
    //         IERC20.transfer.selector,
    //         user1,
    //         transferAmount
    //     );

    //     // Execute as controller
    //     vm.startPrank(controller1);
    //     wallet.controllerExecute(address(token), transferAmount, transferData, TOKEN_OPERATIONS);
    //     vm.stopPrank();
        
    //     assertEq(token.balanceOf(user1), transferAmount);
    // }

    // function testRevertUnauthorizedTokenOperation() public {
    //     vm.startPrank(user2); // user2 has no permissions
    //     bytes memory transferData = abi.encodeWithSelector(
    //         IERC20.transfer.selector,
    //         user2,
    //         100 * 10**token.decimals()
    //     );
    //     wallet.controllerExecute(address(token), 0, transferData, TOKEN_OPERATIONS);
    //     vm.stopPrank();
    // }

    // function testERC20BalanceAndDeposit() public {
    //     uint256 initialWalletBalance = token.balanceOf(address(wallet));
    //     uint256 depositAmount = 100 * 10**token.decimals();
        
    //     // Transfer tokens to user1 first
    //     bytes memory transferData = abi.encodeWithSelector(
    //         IERC20.transfer.selector,
    //         user1,
    //         depositAmount
    //     );
    //     wallet.ownerExecute(address(token), 0, transferData);
        
    //     // User1 approves wallet to receive tokens
    //     vm.startPrank(user1);
    //     token.approve(address(wallet), depositAmount);
        
    //     // User1 deposits tokens into wallet
    //     bytes memory depositData = abi.encodeWithSelector(
    //         IERC20.transferFrom.selector,
    //         user1,
    //         address(wallet),
    //         depositAmount
    //     );
    //     wallet.controllerExecute(address(token), depositAmount, depositData, TOKEN_OPERATIONS);
    //     vm.stopPrank();
        
    //     // Verify wallet balance increased
    //     assertEq(token.balanceOf(address(wallet)), initialWalletBalance);
    // }

    // function testERC20Withdrawal() public {
    //     uint256 withdrawalAmount = 50 * 10**token.decimals();
        
    //     // Withdraw tokens using owner
    //     bytes memory withdrawData = abi.encodeWithSelector(
    //         IERC20.transfer.selector,
    //         user1,
    //         withdrawalAmount
    //     );
    //     wallet.ownerExecute(address(token), 0, withdrawData);
        
    //     // Verify user1 received tokens
    //     assertEq(token.balanceOf(user1), withdrawalAmount);
        
    //     // Withdraw tokens using controller with permission
    //     vm.startPrank(user1);
    //     bytes memory withdrawData2 = abi.encodeWithSelector(
    //         IERC20.transfer.selector,
    //         user2,
    //         withdrawalAmount
    //     );
    //     wallet.controllerExecute(address(token), withdrawalAmount, withdrawData2, TOKEN_OPERATIONS);
    //     vm.stopPrank();
        
    //     // Verify user2 received tokens
    //     assertEq(token.balanceOf(user2), withdrawalAmount);
    // }

    // function testERC20ExternalContractInteraction() public {
    //     uint256 transferAmount = 75 * 10**token.decimals();
        
    //     // First approve external contract to receive tokens
    //     bytes memory approveData = abi.encodeWithSelector(
    //         IERC20.approve.selector,
    //         address(externalContract),
    //         transferAmount
    //     );
    //     wallet.ownerExecute(address(token), 0, approveData);
        
    //     // External contract receives tokens
    //     bytes memory receiveData = abi.encodeWithSelector(
    //         MockExternalContract.receiveTokens.selector,
    //         transferAmount
    //     );
    //     wallet.ownerExecute(address(externalContract), 0, receiveData);
        
    //     // Verify external contract received tokens
    //     assertEq(token.balanceOf(address(externalContract)), transferAmount);
        
    //     // Test external contract interaction with controller permission
    //     vm.startPrank(user1);
    //     // First approve again since previous approval was used
    //     bytes memory approveData2 = abi.encodeWithSelector(
    //         IERC20.approve.selector,
    //         address(externalContract),
    //         transferAmount
    //     );
    //     wallet.controllerExecute(address(token), transferAmount, approveData2, TOKEN_OPERATIONS);
        
    //     // External contract receives tokens again
    //     wallet.controllerExecute(address(externalContract), transferAmount, receiveData, TOKEN_OPERATIONS);
    //     vm.stopPrank();
        
    //     // Verify external contract received tokens twice
    //     assertEq(token.balanceOf(address(externalContract)), transferAmount * 2);
    // }
}
