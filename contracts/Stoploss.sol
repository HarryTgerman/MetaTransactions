//
// Original work by Pine.Finance
//  - https://github.com/pine-finance
//
// Authors:
//  - Ignacio Mazzara <@nachomazzara>
//  - Agustin Aguilar <@agusx1211>

//
//
//                                                /
//                                                @,
//                                               /&&
//                                              &&%%&/
//                                            &%%%%&%%,..
//                                         */%&,*&&&&&&%%&*
//                                           /&%%%%%%%#.
//                                    ./%&%%%&#/%%%%&#&%%%&#(*.
//                                         .%%%%%%%&&%&/ ..,...
//                                       .*,%%%%%%%%%&&%%%%(
//                                     ,&&%%%&&*%%%%%%%%.*(#%&/
//                                  ./,(*,*,#%%%%%%%%%%%%%%%(,
//                                 ,(%%%%%%%%%%%%&%%%%%%%%%#&&%%%#/(*
//                                     *#%%%%%%%&%%%&%%#%%%%%%(
//                              .(####%%&%&#*&%%##%%%%%%%%%%%#.,,
//                                      ,&%%%%%###%%%%%%%%%%%%#&&.
//                             ..,(&%%%%%%%%%%%%%%%%%%&&%%%%#%&&%&%%%%&&#,
//                           ,##//%((#*/#%%%%%%%%%%%%%%%%%%%%%&(.
//                                  (%%%%%%%%%%%%%%%%%%%#%%%%%%%%%&&&&#(*,
//                                   ./%%%%&%%%%#%&%%%%%%##%%&&&&%%(*,
//                                #%%%%%%&&%%%#%%%%%%%%%%%%%%%&#,*&&#.
//                            /%##%(%&/ #%%%%%%%%%%%%%%%%%%%%%%%%%&%%%.
//                                 *&%%%%&%%%%%%%%#%%%%%%%%%%%%%%%%%&%%%#%#%%,
//                        .*(#&%%%%%%%%&&%%%%%%%%%%#%%%%%%%%%%%%%%%(,
//                    ./#%%%%%%%%%%%%%%%%%%%%%%%#%&%#%%%%%%%%%%%%%%%%%%%%&%%%#####(.
//                          .,,*#%%%%%%%%%%%%%##%%&&%#%%%%%%%%&&%%%%%%(&*#&**/(*
//                        .,(&%%%%%#((%%%%%%#%%%%%%%%%#%%%%%%%&&&&&%%%%&%*
//                         ,,,,,..*&%%%%%%%%%%%%%%%%%%%%%%%&%%%%%%%%%#/*.
//                           ,#&%%%%%%%%%%%%%%%%%%%%%%%%&%%%%%%%%%%%%%%%%%%/,
//           .     .,*(#%%%%%%%%%&&&&%%%%%%&&&%%%%%%%%%&&%##%%%%%#,(%%%%%%%%%%%(((*
//             ,/((%%%%%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#%%%%%%%&#  . . ...
//                      .,.,,**(%%%%%%%%&%##%%%%%%%%%%%%%%%%%%###%%%%%%%%%&*
//                       ,%&%%%%%&&%%%%%%%#%%%%%%%%%%%%%%%%%%&%%%%##%%%%%%%%%%%%%%%%&&#.
//              .(&&&%%%%%%&#&&%&%%%%%%%##%%%%&&%%%#%%%%%%&%%%%%%&&%%%%&&&/*(,(#(,,.
//                         ..&%%%%%%#%#%%%%%%%%%%%##%%%%%%%&%%%%%%%%%%%%%%%%&&(.
//                      ,%%%%%%%%%##%%%&%%%%%%%%&%%#%%&&%%%%&%%%%%%&%%%%%&(#%%%#,
//              ./%&%%%%%%%%%%%%%%%%%%%%%%%%%&&&%%%##%%%%%%%%%%%%%&&&%%%%%%%%&#.//*/,..
//      ,#%%%%%%%%%%%%%%%%%%&&%%%%%&&&&%%%%%&&&%%%%%#%%%%#%%%%%%%%%%%%%%%%%%%%%%%%%%&&(,..
//            ,#* ,&&&%,.,*(%%%%%%%%%&%%%%&&&%%%%%&%%%%#%%%%##%%%%%%%&&%%%%%%%%%%%#%%%%%%%%&%(*.
//          .,,/((#%&%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&%#%%%%%%%%%%%%%%%%%#%%%%%%%((*
// *,//**,...,/#%%%%%%%%%%%&&&&%%%%%%%%%%%%%#%%%%%%&&&%%%%&&&&%%%#%%#%%%%%%%%%%%%%%%#*.       .,(#%&@*
//  .*%%(*(%%%%%%%%%%&&&&&&&&%%%%%%%&&%%%%%%%%%%%%%&&&%%%%%%%%%##%%%%%%%%%%%%%%%%%%%%%%%%%%%&%%%/..
//      .,/%&%%%%%%@#(&%&%%%%%%%%%#&&%%##%#%%%#%%%%&&&%%%%%%%%###%%%%%&&&%%%%%%%%%%%%%%%%&(//%%/
//          ,..     .(%%%%##%%%#%%%%%%#%%%%%##%%%%%&&&&%%%%%%%#&%#%%%%%%&&&%%%%%##//  ,,.
//            .,(%#%%##%%%#%%%#%%%#%%*,.*%%%%%%%%%&.,/&%%%%%%% #&%%#%%%%%&%(&%((%&&&(*
//                        ,/#/(%%,    ,&%%#%/.//         %*&(%#    .(,(%%%.

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libs/PineUtils.sol";
import "./libs/SafeERC20.sol";
import "./libs/SafeMath.sol";
import "./Interfaces/IModule.sol";
import "./Interfaces/IHandler.sol";
import "./Interfaces/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */

// File: contracts/interfaces/IModule.sol

// File: contracts/interfaces/IHandler.sol

// File: contracts/commons/Order.sol

contract Order {
    address public constant ETH_ADDRESS =
        address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

// File: contracts/modules/LimitOrders.sol

/*
 * Original work by Pine.Finance
 * - https://github.com/pine-finance
 *
 * Authors:
 * - Agustin Aguilar <agusx1211>
 * - Ignacio Mazzara <nachomazzara>
 */
contract Stoploss is IModule, Order {
    using SafeMath for uint256;

    /// @notice receive ETH
    receive() external payable override {}

    /**
     * @notice Executes an order
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _data - Bytes of the order's data
     * @param _auxData - Bytes of the auxiliar data used for the handlers to execute the order
     * @return protectedFunds - amount of output token in saved value
     */
    function execute(
        IERC20 _inputToken,
        uint256,
        address payable _owner,
        bytes calldata _data,
        bytes calldata _auxData
    ) external override returns (uint256 protectedFunds) {
        (IERC20 outputToken, uint256 _stoploss, uint256 _slippage) = abi.decode(
            _data,
            (IERC20, uint256, uint256)
        );

        IHandler handler = abi.decode(_auxData, (IHandler));

        // Do not trust on _inputToken, it can mismatch the real balance
        uint256 inputAmount = PineUtils.balanceOf(_inputToken, address(this));
        // Handler gets Input Tokens
        _transferAmount(_inputToken, address(handler), inputAmount);

        handler.handle(
            _inputToken,
            outputToken,
            inputAmount,
            _stoploss,
            _auxData
        );

        protectedFunds = PineUtils.balanceOf(outputToken, address(this));
        require(
            protectedFunds <= _stoploss,
            "StopLossOrders#execute: STOPLOSS_THRESHOLD_NOT_REACHED"
        );
        require(
            protectedFunds >= _slippage,
            "StopLossOrders#execute: OUTSIDE_SLIPPAGE"
        );

        _transferAmount(outputToken, _owner, protectedFunds);

        return protectedFunds;
    }

    /**
     * @notice Check whether an order can be executed or not
     * @param _inputToken - Address of the input token
     * @param _inputAmount - uint256 of the input token amount (order amount)
     * @param _data - Bytes of the order's data
     * @param _auxData - Bytes of the auxiliar data used for the handlers to execute the order
     * @return bool - whether the order can be executed or not
     */
    function canExecute(
        IERC20 _inputToken,
        uint256 _inputAmount,
        bytes calldata _data,
        bytes calldata _auxData
    ) external view override returns (bool) {
        (IERC20 outputToken, uint256 _stoploss, uint256 _slippage) = abi.decode(
            _data,
            (IERC20, uint256, uint256)
        );
        IHandler handler = abi.decode(_auxData, (IHandler));

        return
            handler.canHandleStoploss(
                _inputToken,
                outputToken,
                _inputAmount,
                _stoploss,
                _slippage,
                _auxData
            );
    }

    /**
     * @notice Transfer token or Ether amount to a recipient
     * @param _token - Address of the token
     * @param _to - Address of the recipient
     * @param _amount - uint256 of the amount to be transferred
     */
    function _transferAmount(
        IERC20 _token,
        address payable _to,
        uint256 _amount
    ) internal {
        if (address(_token) == ETH_ADDRESS) {
            (bool success, ) = _to.call{value: _amount}("");
            require(
                success,
                "LimitOrders#_transferAmount: ETH_TRANSFER_FAILED"
            );
        } else {
            require(
                SafeERC20.transfer(_token, _to, _amount),
                "LimitOrders#_transferAmount: TOKEN_TRANSFER_FAILED"
            );
        }
    }
}
