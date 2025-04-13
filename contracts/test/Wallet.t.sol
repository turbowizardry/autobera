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
  Wallet public wallet;
  ControllerRegistry public registry;
  WalletPermissions public permissions;
  address public owner;
  address public controller;
  bytes32 public constant PERMISSION_KEY = keccak256("TEST_PERMISSION");

  function setUp() public {
    owner = makeAddr("owner");
    controller = makeAddr("controller");
    
    // Deploy contracts
    registry = new ControllerRegistry();
    permissions = new WalletPermissions(address(registry));
    wallet = new Wallet();
    
    // Initialize wallet
    wallet.initialize(owner, address(registry), address(permissions));
  }

  function test_Initialize() public {
    assertEq(wallet.owner(), owner);
    assertEq(address(wallet.controllerRegistry()), address(registry));
    assertEq(address(wallet.walletPermissions()), address(permissions));
    assertTrue(wallet.initialized());
  }

  function test_Initialize_AlreadyInitialized() public {
    vm.expectRevert("Already initialized");
    wallet.initialize(owner, address(registry), address(permissions));
  }

  function test_Initialize_InvalidOwner() public {
    Wallet newWallet = new Wallet();
    vm.expectRevert("Invalid owner");
    newWallet.initialize(address(0), address(registry), address(permissions));
  }

  function test_Initialize_InvalidControllerRegistry() public {
    Wallet newWallet = new Wallet();
    vm.expectRevert("Invalid controller registry");
    newWallet.initialize(owner, address(0), address(permissions));
  }

  function test_Initialize_InvalidPermissions() public {
    Wallet newWallet = new Wallet();
    vm.expectRevert("Invalid permissions contract");
    newWallet.initialize(owner, address(registry), address(0));
  }

  function test_OwnerExecute() public {
    address target = makeAddr("target");
    bytes memory data = abi.encodeWithSignature("test()");
    
    vm.startPrank(owner);
    wallet.ownerExecute(target, 0, data);
    vm.stopPrank();
  }

  function test_OwnerExecute_NotOwner() public {
    address notOwner = makeAddr("notOwner");
    address target = makeAddr("target");
    bytes memory data = abi.encodeWithSignature("test()");
    
    vm.startPrank(notOwner);
    vm.expectRevert("Not owner");
    wallet.ownerExecute(target, 0, data);
    vm.stopPrank();
  }

  function test_OwnerExecute_ZeroTarget() public {
    bytes memory data = abi.encodeWithSignature("test()");
    
    vm.startPrank(owner);
    vm.expectRevert("Zero target address");
    wallet.ownerExecute(address(0), 0, data);
    vm.stopPrank();
  }

  function test_ControllerExecute() public {
    // Register controller and approve permission
    vm.startPrank(owner);
    registry.registerController(controller, PERMISSION_KEY, "Test Controller", "Test Description");
    permissions.approvePermission(address(wallet), controller, PERMISSION_KEY);
    vm.stopPrank();

    address target = makeAddr("target");
    bytes memory data = abi.encodeWithSignature("test()");
    
    vm.startPrank(controller);
    wallet.controllerExecute(target, 0, data, PERMISSION_KEY);
    vm.stopPrank();
  }

  function test_ControllerExecute_NoPermission() public {
    address target = makeAddr("target");
    bytes memory data = abi.encodeWithSignature("test()");
    
    vm.startPrank(controller);
    vm.expectRevert("Permission denied");
    wallet.controllerExecute(target, 0, data, PERMISSION_KEY);
    vm.stopPrank();
  }

  function test_ControllerExecute_ZeroTarget() public {
    // Register controller and approve permission
    vm.startPrank(owner);
    registry.registerController(controller, PERMISSION_KEY, "Test Controller", "Test Description");
    permissions.approvePermission(address(wallet), controller, PERMISSION_KEY);
    vm.stopPrank();

    bytes memory data = abi.encodeWithSignature("test()");
    
    vm.startPrank(controller);
    vm.expectRevert("Zero target address");
    wallet.controllerExecute(address(0), 0, data, PERMISSION_KEY);
    vm.stopPrank();
  }
}
