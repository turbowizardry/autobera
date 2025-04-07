// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console, Vm} from "forge-std/Test.sol";
import {WalletFactory} from "../src/WalletFactory.sol";
import {Wallet} from "../src/Wallet.sol";
import {ControllerRegistry} from "../src/ControllerRegistry.sol";
import {WalletPermissions} from "../src/WalletPermissions.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IWallet} from "../src/interfaces/IWallet.sol";

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
  WalletPermissions public walletPermissions;
  MockERC20 public token;
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
    walletPermissions = new WalletPermissions(address(controllerRegistry));
    walletImplementation = new Wallet();
    factory = new WalletFactory(
      address(walletImplementation),
      address(controllerRegistry),
      address(walletPermissions)
    );
    
    // Deploy test tokens
    token = new MockERC20();
    externalContract = new MockExternalContract(address(token));

    // Register controller in registry
    controllerRegistry.registerController(
      controller1, 
      TOKEN_OPERATIONS, 
      "Token Operations", 
      "Token operations permission"
    );

    // Setup initial balances
    vm.deal(address(user1), 100 ether);
    token.transfer(address(user1), 1000 * 10**token.decimals());

    // Deploy wallet clone for user1
    vm.startPrank(user1);
    wallet = IWallet(payable(factory.createWallet()));
    vm.stopPrank();

    // Grant permission to controller
    walletPermissions.setPermission(address(wallet), controller1, TOKEN_OPERATIONS, true);
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

  function testUserDepositERC20ToWallet() public {
    uint256 initialBalance = token.balanceOf(address(user1));
    uint256 depositAmount = 100 * 10**token.decimals();

    // Deposit ERC20 using user1
    vm.startPrank(user1);
    token.approve(address(user1), depositAmount);
    token.transfer(address(wallet), depositAmount);
    vm.stopPrank();

    assertEq(token.balanceOf(address(user1)), initialBalance - depositAmount);
    assertEq(token.balanceOf(address(wallet)), depositAmount);
  }

  function testUserTransferERC20ToAndFromWallet() public {
    uint256 userInitialBalance = token.balanceOf(address(user1));
    uint256 walletInitialBalance = token.balanceOf(address(wallet));
    uint256 withdrawAmount = 100 * 10**token.decimals();

    // Deposit ERC20 using user1
    vm.startPrank(user1);
    token.approve(address(user1), withdrawAmount);
    token.transfer(address(wallet), withdrawAmount);
    vm.stopPrank();

    assertEq(token.balanceOf(address(user1)), userInitialBalance - withdrawAmount);
    assertEq(token.balanceOf(address(wallet)), walletInitialBalance + withdrawAmount);

    // Withdraw ERC20 using user1
    bytes memory transferData = abi.encodeWithSelector(
      IERC20.transfer.selector,
      user1,
      withdrawAmount
    );
    
    vm.startPrank(user1);
    wallet.ownerExecute(address(token), 0, transferData);
    vm.stopPrank();

    assertEq(token.balanceOf(address(user1)), userInitialBalance);
    assertEq(token.balanceOf(address(wallet)), walletInitialBalance);
  }

  function testControllerOperations() public {
    uint256 userInitialBalance = token.balanceOf(address(user1));
    uint256 transferAmount = 100 * 10**token.decimals();
    
    vm.startPrank(user1);
    token.approve(address(user1), transferAmount);
    token.transfer(address(wallet), transferAmount);
    vm.stopPrank();

    bytes memory transferData = abi.encodeWithSelector(
      IERC20.transfer.selector,
      user1,
      transferAmount
    );

    // Execute as controller1 instead of owner
    vm.startPrank(controller1);
    wallet.controllerExecute(address(token), 0, transferData, TOKEN_OPERATIONS);
    vm.stopPrank();
    
    assertEq(token.balanceOf(user1), userInitialBalance);
  }

  function testRevertIfUnauthorizedController() public {
    address unauthorizedController = makeAddr("unauthorizedController");
    bytes memory transferData = abi.encodeWithSelector(
      IERC20.transfer.selector,
      user1,
      100 * 10**token.decimals()
    );

    vm.startPrank(unauthorizedController);
    vm.expectRevert("Permission denied");
    wallet.controllerExecute(address(token), 0, transferData, TOKEN_OPERATIONS);
    vm.stopPrank();
  }
}
