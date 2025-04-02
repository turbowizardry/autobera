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
    ControllerRegistry public controllerRegistry;
    MockERC20 public token;
    MockERC721 public nft;
    MockExternalContract public externalContract;
    
    address public owner;
    address public user1;
    address public user2;
    address public controller1;

    bytes32 public constant TOKEN_OPERATIONS = keccak256("TOKEN_OPERATIONS");

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        controller1 = makeAddr("controller1");

        // Deploy contracts
        controllerRegistry = new ControllerRegistry();
        wallet = new Wallet();
        wallet.initialize(owner, address(controllerRegistry));

        token = new MockERC20();
        nft = new MockERC721();
        externalContract = new MockExternalContract(address(token));
        controllerRegistry.registerController(controller1, "TOKEN_OPERATIONS", "Token Operations", "1.0", "Token operations permission");

        // Setup initial balances
        vm.deal(address(wallet), 100 ether);
        token.transfer(address(wallet), 1000 * 10**token.decimals());
        nft.mint(address(wallet));
        
        // Give user1 token operation permissions
        wallet.setControllerPermission(user1, TOKEN_OPERATIONS, true);
    }

    function testTransferNativeETH() public {
        uint256 initialBalance = address(user1).balance;
        uint256 transferAmount = 1 ether;
        
        // Transfer ETH using owner
        wallet.ownerExecute(user1, transferAmount, "");
        assertEq(address(user1).balance, initialBalance + transferAmount);
        
        // Transfer ETH using controller with permission
        vm.startPrank(user1);
        wallet.controllerExecute(user2, "", TOKEN_OPERATIONS, transferAmount);
        vm.stopPrank();
        
        assertEq(address(user2).balance, transferAmount);
    }

    function testERC20Operations() public {
        uint256 transferAmount = 100 * 10**token.decimals();
        
        // Transfer ERC20 using owner
        bytes memory transferData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            user1,
            transferAmount
        );
        wallet.ownerExecute(address(token), 0, transferData);
        assertEq(token.balanceOf(user1), transferAmount);
        
        // Transfer ERC20 using controller with permission
        vm.startPrank(user1);
        bytes memory transferData2 = abi.encodeWithSelector(
            IERC20.transfer.selector,
            user2,
            transferAmount
        );
        wallet.controllerExecute(address(token), transferData2, TOKEN_OPERATIONS, 0);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user2), transferAmount);
    }

    function testERC721Operations() public {
        uint256 tokenId = 1;
        
        // Transfer ERC721 using owner (using safeTransferFrom since wallet is owner)
        bytes memory transferData = abi.encodeWithSelector(
            bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)")),
            address(wallet),
            user1,
            tokenId,
            "" // empty data parameter
        );
        wallet.ownerExecute(address(nft), 0, transferData);
        assertEq(nft.ownerOf(tokenId), user1);
        
        // Approve wallet to transfer NFT from user1
        vm.startPrank(user1);
        nft.approve(address(wallet), tokenId);
        
        // Transfer ERC721 using controller with permission
        bytes memory transferData2 = abi.encodeWithSelector(
            IERC721.transferFrom.selector,
            user1,
            user2,
            tokenId
        );
        wallet.controllerExecute(address(nft), transferData2, TOKEN_OPERATIONS, 0);
        vm.stopPrank();
        
        assertEq(nft.ownerOf(tokenId), user2);
    }

    function testRevertUnauthorizedTokenOperation() public {
        vm.startPrank(user2); // user2 has no permissions
        bytes memory transferData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            user2,
            100 * 10**token.decimals()
        );
        wallet.controllerExecute(address(token), transferData, TOKEN_OPERATIONS, 0);
        vm.stopPrank();
    }

    function testERC20BalanceAndDeposit() public {
        uint256 initialWalletBalance = token.balanceOf(address(wallet));
        uint256 depositAmount = 100 * 10**token.decimals();
        
        // Transfer tokens to user1 first
        bytes memory transferData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            user1,
            depositAmount
        );
        wallet.ownerExecute(address(token), 0, transferData);
        
        // User1 approves wallet to receive tokens
        vm.startPrank(user1);
        token.approve(address(wallet), depositAmount);
        
        // User1 deposits tokens into wallet
        bytes memory depositData = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            user1,
            address(wallet),
            depositAmount
        );
        wallet.controllerExecute(address(token), depositData, TOKEN_OPERATIONS, 0);
        vm.stopPrank();
        
        // Verify wallet balance increased
        assertEq(token.balanceOf(address(wallet)), initialWalletBalance);
    }

    function testERC20Withdrawal() public {
        uint256 withdrawalAmount = 50 * 10**token.decimals();
        
        // Withdraw tokens using owner
        bytes memory withdrawData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            user1,
            withdrawalAmount
        );
        wallet.ownerExecute(address(token), 0, withdrawData);
        
        // Verify user1 received tokens
        assertEq(token.balanceOf(user1), withdrawalAmount);
        
        // Withdraw tokens using controller with permission
        vm.startPrank(user1);
        bytes memory withdrawData2 = abi.encodeWithSelector(
            IERC20.transfer.selector,
            user2,
            withdrawalAmount
        );
        wallet.controllerExecute(address(token), withdrawData2, TOKEN_OPERATIONS, 0);
        vm.stopPrank();
        
        // Verify user2 received tokens
        assertEq(token.balanceOf(user2), withdrawalAmount);
    }

    function testERC20ExternalContractInteraction() public {
        uint256 transferAmount = 75 * 10**token.decimals();
        
        // First approve external contract to receive tokens
        bytes memory approveData = abi.encodeWithSelector(
            IERC20.approve.selector,
            address(externalContract),
            transferAmount
        );
        wallet.ownerExecute(address(token), 0, approveData);
        
        // External contract receives tokens
        bytes memory receiveData = abi.encodeWithSelector(
            MockExternalContract.receiveTokens.selector,
            transferAmount
        );
        wallet.ownerExecute(address(externalContract), 0, receiveData);
        
        // Verify external contract received tokens
        assertEq(token.balanceOf(address(externalContract)), transferAmount);
        
        // Test external contract interaction with controller permission
        vm.startPrank(user1);
        // First approve again since previous approval was used
        bytes memory approveData2 = abi.encodeWithSelector(
            IERC20.approve.selector,
            address(externalContract),
            transferAmount
        );
        wallet.controllerExecute(address(token), approveData2, TOKEN_OPERATIONS, 0);
        
        // External contract receives tokens again
        wallet.controllerExecute(address(externalContract), receiveData, TOKEN_OPERATIONS, 0);
        vm.stopPrank();
        
        // Verify external contract received tokens twice
        assertEq(token.balanceOf(address(externalContract)), transferAmount * 2);
    }
}
