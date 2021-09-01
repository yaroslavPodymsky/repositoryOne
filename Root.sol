pragma ton-solidity >= 0.43.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "./interfaces/IRoot.sol";
import "./interfaces/IWallet.sol";
import "./resolvers/WalletResolver.sol";
import "./libraries/Errors.sol";

contract Root is IRoot, WalletResolver {

    modifier onlyOwner() {
        if(_addrOwner != address(0) && msg.sender != address(0)) {
            require(msg.sender == _addrOwner, Errors.ACCESS_DENIED);
        } else if(_pubkeyOwner != 0 && msg.pubkey() != 0) {
            require(msg.pubkey() == _pubkeyOwner, Errors.ACCESS_DENIED);
            tvm.accept();
        }
        _;
    }

    function _checkAmount(uint128 amount) private inline {
        require(amount + _totalGranted <= _rootData.totalSupply, Errors.NOT_ENOUGH_TOKENS);
    }

/* -------------------------------------------------------------------------- */
/*                                 ANCHOR init                                */
/* -------------------------------------------------------------------------- */

    RootData public _rootData;

    uint256 public _pubkeyOwner;
    address public _addrOwner; 

    uint128 public _totalGranted;

    constructor(
        RootData rootData,
        uint256 pubkeyOwner,
        address addrOwner
    ) public {
        require(pubkeyOwner != 0 || addrOwner != address(0));
        tvm.accept();
        _rootData = rootData;

        _pubkeyOwner = pubkeyOwner;
        _addrOwner = addrOwner;
    }

    function uploadWalletCode(
        TvmCell codeWallet
    ) external onlyOwner {
        if(msg.sender != address(0)) {
            require(msg.value >= 0.4 ton);
        }
        _codeWallet = codeWallet;
    }

    

/* -------------------------------------------------------------------------- */
/*                            ANCHOR deploy wallets                           */
/* -------------------------------------------------------------------------- */

    function deployWallet(
        uint256 pubkeyOwner,
        address addrOwner,
        uint128 initialAmount
    ) external override returns (address addrWallet) {
        require(pubkeyOwner != 0 || addrOwner != address(0), Errors.WALLET_OWNER_NOT_SPECIFIED);
        _checkAmount(initialAmount);
        if(msg.pubkey() == _pubkeyOwner) {
            tvm.accept();
            TvmCell state = _buildWalletState(address(this), pubkeyOwner, addrOwner);
            addrWallet = new Wallet
                {stateInit: state, value: 0.4 ton}
                (initialAmount);
        } else if(msg.sender != address(0)) {
            require(msg.value >= 1 ton, Errors.NOT_ENOUGH_VALUE);
            TvmCell state = _buildWalletState(address(this), pubkeyOwner, addrOwner);
            if(msg.sender == addrOwner) {
                addrWallet = new Wallet
                    {stateInit: state, value: 0.4 ton}
                    (initialAmount);
            } else {
                require(initialAmount == 0, Errors.ONLY_OWNER_CAN_DISTRIBUTE_TOKENS);
                addrWallet = new Wallet
                    {stateInit: state, value: 0.4 ton}
                    (0);
            }
            msg.sender.transfer(0, false, 64);
        } else {
            require(false, Errors.ACCESS_DENIED);
        }
        
        _totalGranted += initialAmount;

        return addrWallet ;
    }

/* -------------------------------------------------------------------------- */
/*                                ANCHOR grants                               */
/* -------------------------------------------------------------------------- */

    function grant(
        address addrWallet,
        uint128 amount
    ) external onlyOwner {
        if(msg.sender != address(0)) {
            require(msg.value >= 1 ton, Errors.NOT_ENOUGH_VALUE);
        }
        _checkAmount(amount);
        require(addrWallet != address(0), Errors.RECIPIENT_ADDRESS_NOT_SPECIFIED);

        IWallet(addrWallet).recieve{value: 0.2 ton, flag: 1}(amount, 0, address(0));

        _totalGranted += amount;
    }
}