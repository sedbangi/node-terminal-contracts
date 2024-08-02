// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IOrbiterNodes {
    function totalMint() external view returns (uint256);
    function mint(address) external returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

interface IOrbiterNodeSale {
    event MintNode(
        uint256 indexed id,
        address indexed buyer,
        uint256 indexed cycle,
        uint256 price,
        uint256 discountPrice,
        string invitationCode
    );

    struct NodePurchaseParams {
        uint256 price;
        uint256 discountPrice;
        uint256 buyerMaxLimit;
        string invitationCode;
    }

    struct CycleInfo {
        uint128 cycle;
        uint128 nodesNumber;
        uint256 price;
    }
}

contract OrbiterNodeSale is
    Ownable,
    ReentrancyGuard,
    AccessControl,
    Pausable,
    IOrbiterNodeSale
{
    using MessageHashUtils for bytes32;
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    address public nodesNFT;

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    CycleInfo[] public cycleinfo;

    mapping(address => bool) public availablePaymentTokens;

    mapping(address => string) public userBindingInvitationCode;

    address public feesReceiver;

    uint256 public maxBatchMintNum;

    constructor(
        address owner_,
        address nodesNFT_,
        address feesReceiver_,
        uint256 maxBatchMintNum_,
        address[] memory availablePaymentTokens_,
        address[] memory signers_,
        address[] memory governors_,
        uint128[] memory nodesNumbers_,
        uint256[] memory prices_
    ) Ownable(owner_) {
        require(owner_ != address(0), "ONS: owner is zero");

        require(nodesNFT_ != address(0), "ONS: reward token is zero");

        require(feesReceiver_ != address(0), "ONS: fees receiver is zero");

        require(
            maxBatchMintNum_ > 0,
            "ONS: maxBatchMintNum must be greater than 0"
        );

        nodesNFT = nodesNFT_;

        feesReceiver = feesReceiver_;

        maxBatchMintNum = maxBatchMintNum_;

        _setNewCycleInfo(nodesNumbers_, prices_);

        _grantRole(DEFAULT_ADMIN_ROLE, owner_);

        for (uint256 i = 0; i < governors_.length; i++) {
            require(governors_[i] != address(0), "ONS: governor is zero");
            _grantRole(GOVERNOR_ROLE, governors_[i]);
        }

        for (uint256 i = 0; i < signers_.length; i++) {
            require(signers_[i] != address(0), "ONS: signer is zero");
            _grantRole(SIGNER_ROLE, signers_[i]);
        }

        for (uint256 i = 0; i < availablePaymentTokens_.length; i++) {
            require(
                availablePaymentTokens_[i] != address(0),
                "ONS: payment token is zero"
            );
            availablePaymentTokens[availablePaymentTokens_[i]] = true;
        }
    }

    function mint(
        NodePurchaseParams calldata node,
        address paymentToken,
        uint256 batchMintNumber,
        bytes calldata signature
    ) external nonReentrant whenNotPaused {
        require(
            availablePaymentTokens[paymentToken],
            "ONS: payment token not available"
        );

        require(
            _signatureVerify(_encode(msg.sender, node), signature),
            "ONS: signature error"
        );

        require(
            _balanceOf(msg.sender) + batchMintNumber <= node.buyerMaxLimit,
            "ONS: limit over threshold"
        );

        require(
            batchMintNumber > 0 && batchMintNumber <= maxBatchMintNum,
            "ONS: mintNumber must be greater than 0"
        );

        for (uint256 i = 0; i < batchMintNumber; i++) {
            CycleInfo memory cycle = _calculateCurrentCycle();

            require(node.price == cycle.price, "ONS: priceNotMatch");

            {
                bool isUseDiscontPrice = node.discountPrice > 0 &&
                    node.discountPrice != node.price;

                if (bytes(node.invitationCode).length > 0) {
                    string memory bidingCode = userBindingInvitationCode[
                        msg.sender
                    ];
                    if (bytes(bidingCode).length > 0) {
                        require(
                            keccak256(bytes(bidingCode)) ==
                                keccak256(bytes(node.invitationCode)),
                            "ONS: invitationCode not matched"
                        );
                    } else {
                        userBindingInvitationCode[msg.sender] = node
                            .invitationCode;
                    }
                }

                uint256 payAmount = isUseDiscontPrice
                    ? node.discountPrice
                    : node.price;

                IERC20(paymentToken).safeTransferFrom(
                    msg.sender,
                    feesReceiver,
                    payAmount
                );
            }

            emit MintNode(
                _mintNFT(msg.sender),
                msg.sender,
                cycle.cycle,
                cycle.price,
                node.discountPrice,
                node.invitationCode
            );
        }
    }

    function encode(
        address buyer,
        NodePurchaseParams memory node
    ) public pure returns (bytes32 data) {
        data = _encode(buyer, node);
    }

    /****governance */

    /*** owner part start*/
    function transferOwnership(
        address newOwner
    ) public override onlyOwner nonReentrant {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
    }

    function setFeesReceiver(address receiver) external onlyOwner {
        require(receiver != address(0), "ONS: receiver is zero");
        feesReceiver = receiver;
    }

    function setNodesNFT(address token) external onlyOwner {
        require(token != address(0), "ONS: reward token is zero");
        nodesNFT = token;
    }
    /*** owner part end*/

    /*** governor part start */
    function setMaxBatchMintNum(
        uint256 _maxBatchMintNum
    ) external onlyRole(GOVERNOR_ROLE) {
        require(
            _maxBatchMintNum > 0,
            "ONS: maxBatchMintNum must be greater than 0"
        );
        maxBatchMintNum = _maxBatchMintNum;
    }

    function clearBindingInvitationCode(
        address buyer
    ) external onlyRole(GOVERNOR_ROLE) {
        userBindingInvitationCode[buyer] = "";
    }

    function resetCycleInfo(
        uint128[] calldata cycles,
        uint128[] calldata nodesNumbers,
        uint256[] calldata prices
    ) external onlyRole(GOVERNOR_ROLE) {
        _resetCycleInfo(cycles, nodesNumbers, prices);
    }

    function setNewCycleInfo(
        uint128[] calldata nodesNumbers,
        uint256[] calldata prices
    ) external onlyRole(GOVERNOR_ROLE) {
        _setNewCycleInfo(nodesNumbers, prices);
    }

    function setAvailablePaymentTokens(
        address[] calldata tokens,
        bool[] calldata status
    ) external onlyRole(GOVERNOR_ROLE) {
        require(tokens.length == status.length, "ONS: invalid length");
        for (uint256 i = 0; i < tokens.length; i++) {
            availablePaymentTokens[tokens[i]] = status[i];
        }
    }

    function setSigners(
        address[] calldata signers,
        bool[] calldata status
    ) external onlyRole(GOVERNOR_ROLE) {
        for (uint256 i = 0; i < signers.length; i++) {
            require(signers[i] != address(0), "ONS: signer is zero");
            if (status[i]) {
                _grantRole(SIGNER_ROLE, signers[i]);
            } else {
                _revokeRole(SIGNER_ROLE, signers[i]);
            }
        }
    }

    function withdraw(
        address token,
        uint256 amount
    ) external onlyRole(GOVERNOR_ROLE) nonReentrant {
        IERC20(token).safeTransfer(feesReceiver, amount);
    }

    function pause(bool _paused) external onlyRole(GOVERNOR_ROLE) {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }
    /*** governor part end */

    function getCycleInfo() external view returns (CycleInfo[] memory) {
        return cycleinfo;
    }

    function signatureVerify(
        bytes32 _hash,
        bytes memory _signature
    ) external pure returns (address recoverAddress) {
        recoverAddress = address(
            uint160(_hash.toEthSignedMessageHash().recover(_signature))
        );
    }

    function _signatureVerify(
        bytes32 _hash,
        bytes memory _signature
    ) internal view returns (bool) {
        return
            hasRole(
                SIGNER_ROLE,
                address(
                    uint160(_hash.toEthSignedMessageHash().recover(_signature))
                )
            );
    }

    function _encode(
        address buyer,
        NodePurchaseParams memory node
    ) internal pure returns (bytes32 data) {
        data = keccak256(
            abi.encode(
                buyer,
                node.price,
                node.discountPrice,
                node.buyerMaxLimit,
                node.invitationCode
            )
        );
    }

    function _setNewCycleInfo(
        uint128[] memory nodesNumbers,
        uint256[] memory prices
    ) internal {
        require(prices.length == nodesNumbers.length, "ONS: invalid length");
        uint128 currentLength = uint128(cycleinfo.length);
        for (uint128 i = 0; i < prices.length; i++) {
            require(
                nodesNumbers[i] > 0,
                "ONS: nodes number must be greater than 0"
            );
            require(prices[i] > 0, "ONS: nodes price must be greater than 0");
            cycleinfo.push(
                CycleInfo(currentLength + i, nodesNumbers[i], prices[i])
            );
        }
    }

    function _resetCycleInfo(
        uint128[] memory cycles,
        uint128[] memory nodesNumbers,
        uint256[] memory prices
    ) internal {
        require(prices.length == nodesNumbers.length, "ONS: invalid length");
        require(cycles.length == prices.length, "ONS: invalid length");

        CycleInfo memory cycle = _calculateCurrentCycle();

        for (uint256 i = 0; i < prices.length; i++) {
            require(cycles[i] > cycle.cycle, "ONS: coulld not reset end cycle");

            require(
                nodesNumbers[i] > 0,
                "ONS: nodes number must be greater than 0"
            );
            require(prices[i] > 0, "ONS: nodes price must be greater than 0");
            cycleinfo[cycles[i]] = CycleInfo(
                cycles[i],
                nodesNumbers[i],
                prices[i]
            );
        }
    }

    function _calculateCurrentCycle()
        internal
        view
        returns (CycleInfo memory cycle)
    {
        uint256 maxId = _totalMint();
        uint256 cumulAmount = 0;
        for (uint256 i = 0; i < cycleinfo.length; i++) {
            uint256 startId = i == 0 ? 0 : cycleinfo[i - 1].nodesNumber;
            cycle = cycleinfo[i];
            cumulAmount += cycle.nodesNumber;
            uint256 endId = cumulAmount - 1;
            if (maxId >= startId && maxId <= endId) {
                return cycle;
            }
        }

        revert("ONS: Sale ended");
    }

    function calculateCurrentCycle() external view returns (CycleInfo memory) {
        return _calculateCurrentCycle();
    }

    function _mintNFT(address to) internal returns (uint256) {
        return IOrbiterNodes(nodesNFT).mint(to);
    }

    // 0 based
    function _totalMint() internal view returns (uint256) {
        return IOrbiterNodes(nodesNFT).totalMint();
    }

    function _balanceOf(address buyer) internal view returns (uint256) {
        return IOrbiterNodes(nodesNFT).balanceOf(buyer);
    }

    receive() external payable {
        (bool sent, ) = payable(feesReceiver).call{value: msg.value}("");
        (sent);
    }
}
