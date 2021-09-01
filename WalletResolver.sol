pragma ton-solidity >= 0.43.0;

import '../Wallet.sol';

contract WalletResolver {
    TvmCell public _codeWallet;

    function resolveWallet(
        address addrRoot,
        uint256 pubkeyOwner,
        address addrOwner
    ) public view returns (address addrWallet) {
        TvmCell state = _buildWalletState(addrRoot, pubkeyOwner, addrOwner);
        uint256 hashState = tvm.hash(state);
        addrWallet = address.makeAddrStd(0, hashState);
    }
    
    function _buildWalletState(
        address addrRoot,
        uint256 pubkeyOwner,
        address addrOwner
    ) internal view returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Wallet,
            varInit: {
                _addrRoot: addrRoot,
                _pubkeyOwner: pubkeyOwner,
                _addrOwner: addrOwner
            },
            code: _codeWallet
        });
    }
}