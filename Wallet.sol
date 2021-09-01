pragma ton-solidity >= 0.43.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "./interfaces/IWallet.sol";

contract Wallet is IWallet {

    modifier onlyOwner() {
        if(_addrOwner != address(0) && msg.sender != address(0)) {
            require(msg.sender == _addrOwner);
        } else if(_pubkeyOwner != 0 && msg.pubkey() != 0) {
            require(msg.pubkey() == _pubkeyOwner);
            tvm.accept();
        }
        _;
    }

    function _checkAmount(uint128 amount) private inline {
        require(amount <= _balance);
    }

/* -------------------------------------------------------------------------- */
/*                                 ANCHOR init                                */
/* -------------------------------------------------------------------------- */

    address public static _addrRoot;
    uint256 public static _pubkeyOwner;
    address public static _addrOwner; 

    uint128 public _balance;

    constructor(
        uint128 initialAmount
    ) public {
        require(_addrRoot == msg.sender);
        require(_pubkeyOwner != 0 || _addrOwner != address(0));
        _balance += initialAmount;
    }

/* -------------------------------------------------------------------------- */
/*                             ANCHOR transfering                             */
/* -------------------------------------------------------------------------- */

    function transfer(
        address addrWallet,
        uint128 amount
    ) override public onlyOwner {
        if(msg.sender != address(0)) {
            require(msg.value >= 1 ton);
        }
        require(addrWallet != address(0));
        require(amount > 0);

        IWallet(addrWallet).recieve
            {value: 0.2 ton, flag: 1}
            (amount, _pubkeyOwner, _addrOwner);

        _balance -= amount;
    }

    function recieve(
        uint128 amount,
        uint256 pubkeyOwner,
        address addrOwner
    ) override public {
        require(msg.sender != address(0));

        if(msg.sender == _addrRoot) {
            _balance += amount;
        } else {
            require(msg.sender == resolveWallet(pubkeyOwner, addrOwner));
            _balance += amount;
        }
    }

    function resolveWallet(
        uint256 pubkeyOwner,
        address addrOwner
    ) private inline returns (address addrWallet) {
        TvmCell state = _buildWalletState(pubkeyOwner, addrOwner);
        uint256 hashState = tvm.hash(state);
        addrWallet = address.makeAddrStd(0, hashState);
    }
    
    function _buildWalletState(
        uint256 pubkeyOwner,
        address addrOwner
    ) private inline view returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Wallet,
            varInit: {
                _addrRoot: _addrRoot,
                _pubkeyOwner: pubkeyOwner,
                _addrOwner: addrOwner
            },
            code: tvm.code()
        });
    }
}