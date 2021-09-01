pragma ton-solidity >= 0.43.0;

interface IWallet {
    function transfer(address addrWallet, uint128 amount) external;
    function recieve(uint128 amount, uint256 pubkeyOwner, address addrOwner) external;
}

