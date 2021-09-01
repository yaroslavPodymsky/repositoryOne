pragma ton-solidity >= 0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IObject.sol";
import "./ObjectIndex.sol";
import "./resolvers/ObjectIndexResolver.sol";
import "./interfaces/IFactory.sol";

abstract contract Object is IObject, ObjectIndexResolver {

    uint256 static _id;
    uint256 id; //Use non static variables in methods

    string static _VIN;
    string VIN;//Use non static variables in methods

    address _addrOwner;
    address _addrAuthor;
    address _addrChild;
    address _oldChildOwner;
    address _addrFactory;
    address _addrIndex;

    string _objType;
    uint32 _version;

    bool _connectToTree;

    // hash(objectType) 
    mapping(uint256 => ChildObjects) _slots;

    Properties _props;

    modifier onlyOwner() {
        require(msg.sender == _addrOwner, 101);
        tvm.accept();
        _;
    }

    //=========================================================================//
    //Note: If you need to change child`s owner in tree, first you need to divide child from tree
    //Then changeOwner 
    function changeOwner(address addrTo) public override {
        require(msg.sender == _addrOwner);
        tvm.accept();
        
        _addrOwner = addrTo;
        createIndex(_addrOwner); //New owner
    }

    function setConnectionState(bool flag) public override {
        require(msg.sender == _addrOwner);
        tvm.accept();

        _connectToTree = flag;
    }
    
/* -------------------------------------------------------------------------- */
/*                             ANCHOR Unite child                             */
/* -------------------------------------------------------------------------- */

    //See unite in callback
    function uniteChild(address addrChild, string typeChild) private { // root
        if(_slots[tvm.hash(typeChild)].count > _slots[tvm.hash(typeChild)].childrenAddr.length ) {
            _slots[tvm.hash(typeChild)].childrenAddr.push(addrChild);
            IObject(addrChild).deleteIndex(_oldChildOwner);
            IObject(addrChild).setConnectionState(true);
        } else { 
            //What if we can`t connect leaf to the tree?
            //We need to change leaf`s owner to multisig
            IObject(addrChild).changeOwner(_oldChildOwner);
        }
    }

    function divide(address[] arrAddrChild) public override  {
        require(msg.sender == _addrOwner);
        tvm.accept();
        if(arrAddrChild.length > 2) {
            address nextObject = arrAddrChild[arrAddrChild.length - 1];
            arrAddrChild.pop();
            IObject(nextObject).divide(arrAddrChild);
        } else {
            _addrChild = arrAddrChild[1];

            address msig = arrAddrChild[0];

            IObject(_addrChild).setConnectionState(false);

            IObject(_addrChild).sendType(operation.Divide);
            IObject(_addrChild).createIndex(msig);
            IObject(_addrChild).changeOwner(msig); 
        }
    }

    function deleteChild(address addrChild, string typeChild) private {
        tvm.accept();
        for(uint i = 0; i < _slots[tvm.hash(typeChild)].childrenAddr.length; ++i) {
            if(_slots[tvm.hash(typeChild)].childrenAddr[i] == addrChild) {
                _slots[tvm.hash(typeChild)].childrenAddr[i] =
                    _slots[tvm.hash(typeChild)].childrenAddr[
                        _slots[tvm.hash(typeChild)].childrenAddr.length - 1
                    ];
                _slots[tvm.hash(typeChild)].childrenAddr.pop();
            }
        }
    }

    function createIndex(address oldChildOwner) public override {
        require(msg.sender == _addrOwner);
        tvm.accept();
        TvmCell code = _buildObjectIndexCode(oldChildOwner);
        TvmCell state = _buildObjectIndexStateInit(code, address(this));

        _addrIndex = resolveObjectIndexAddress(_addrOwner, address(this));

        new ObjectIndex
            {stateInit: state, value: 0.2 ton}
            ();
    }

    function deleteIndex(address addrOwner) public override {
        require(msg.sender == _addrOwner);
        tvm.accept();
        address addrIndex = resolveObjectIndexAddress(addrOwner, address(this));

        _addrIndex = addrIndex;

        IObjectIndex(addrIndex).destruct();
    }

    /*
    * Callback
    */

/* -------------------------------------------------------------------------- */
/*                                ANCHOR Unite                                */
/* -------------------------------------------------------------------------- */

    function unite(address[] arrAddrChild) public override { // root
        require(msg.sender == _addrOwner);
        tvm.accept();

        if(arrAddrChild.length > 3) {
            address nextObject = arrAddrChild[arrAddrChild.length - 1];
            arrAddrChild.pop();
            IObject(nextObject).unite(arrAddrChild);
        } else {
            _addrChild = arrAddrChild[2];
            _oldChildOwner = arrAddrChild[0];
            IObject(_addrChild).sendType(operation.Unite);
        }
    }

    function setChildType(string typeChild, operation op) public override { // root
        require(msg.sender == _addrChild);
        tvm.accept();

        if(op == operation.Unite) {
            uniteChild(msg.sender, typeChild);
        } else if (op == operation.Divide) {
            deleteChild(msg.sender, typeChild);
        }
    }

    function sendType(operation op) public override { // child
        require(msg.sender == _addrOwner);
        tvm.accept();

        IObject(msg.sender).setChildType(_objType, op);
    }
    
    /*
    * Getters
    */

    function isConnectedToTree() public override view returns (bool) {
        tvm.accept();

        return _connectToTree;
    }

    function getVersionAndType() public override view returns ( uint32 version, string _type ) {
        tvm.accept();
        version = _version;
        _type = _objType;
    }

    function getOwner() public override view returns (address) {
        tvm.accept();
        return _addrOwner;
    }

    function getSlots(string typeChild) public override view returns (address[] childrenAddr) {
        tvm.accept();
        childrenAddr = _slots[tvm.hash(typeChild)].childrenAddr;
    }

    function getInfo() public view override returns (
        Properties props,
        string objType,
        address addrOwner,
        address addrObject,
        address addrAuthor,
        mapping(uint256 => ChildObjects) slots
    ) {
        tvm.accept();

        props = _props;
        objType = _objType;
        addrOwner = _addrOwner;
        addrObject = address(this);
        addrAuthor = _addrAuthor;
        slots = _slots;
    }

    /*
    * Update
    */

    function chainUpdateContract(address[] chainCall) public override {
        // require(msg.sender == _addrOwner, 101);
        tvm.accept();

        if(chainCall.length > 1) {
            address nextObject = chainCall[chainCall.length - 1];
            chainCall.pop();
            IObject(nextObject).chainUpdateContract(chainCall);
        } else {
            address child = chainCall[0];
            IObject(child).updateContract();
        }
    }

    function updateContract() public view override {
        // require(msg.sender == _addrOwner, 101);
        tvm.accept();
        IFactory(_addrFactory).UpdateZeroObj{value: 0.5 ton}(_objType, _version);
    }

    function executeUpdate(Matrix[] updMatrix, uint32 updVersion) public override {
        // require(msg.sender == _addrFactory, 103);
        tvm.accept();

        _version = updVersion;

        //What if we add new objType into slots? 
        //We can`t use old slots anymore, then we delete it and recreate
        delete _slots; 

        address[] empty;

        for (uint i = 0; i < updMatrix.length; i++) {
            _slots[tvm.hash(updMatrix[i].childType)] = ChildObjects(updMatrix[i].childType, updMatrix[i].amount, empty);
        }
    }
}
