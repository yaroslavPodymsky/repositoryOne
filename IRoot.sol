pragma ton-solidity >= 0.43.0;

struct RootData {
    string name;
    string symbol;
    string icon;
    string desc;
    uint8 decimals;
    uint128 totalSupply;
}

interface IRoot {
    function deployWallet(
        uint256 pubkeyOwner,
        address addrOwner,
        uint128 initialAmount
    ) external returns (address addrWallet);
}

interface IRootCb {
    function getDataCb(RootData rootData) external;
}