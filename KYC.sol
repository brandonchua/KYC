pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

contract kyc {
    
    uint256 public bankCount = 0;
    address MAS;
    modifier onlyMAS() {
        require(msg.sender == MAS, "Address is not MAS. Only MAS can add bank.");
        _;
    }
        
    struct Customer {
        string nationalID;
        address ethAddress;
        string dataHash;
        uint upvotes;
        address lastRequestingBank;
        address creatingBank;
        Risk riskRating;
        uint256 createdDate;
    }
    
    //mapping(_KeyType => _ValueType) public mappingName
    mapping (address=>Customer) customers;
    
    //Storing the address for iteration
    address[] customerAddress;
    
    struct Bank {
        string name;
        address ethAddress;
        uint KYC_count;
        string regNumber;
    }
    
    mapping(address=>Bank) banks;
    address[] bankAddress;
    

    struct KYCUpdateHistory
    {
        uint256 kycDate;
        string customerUname;
        address customerEthAddress;
        address bankEthAddress;
    }
    mapping (address=>KYCUpdateHistory[]) customerKYCUpdateHistory;
    address[] updateHistoryaddress;    
    
    enum Risk {
            Low,
            Medium,
            High,
            PendingOverseas
    }

    constructor() public {
        MAS = msg.sender;
    }
    
    function addBank(string memory _bankName, address _bankAddress, string _regNum) public onlyMAS {
        incrementBankCount();
        banks[_bankAddress] = Bank(_bankName, _bankAddress, 0, _regNum);
        //Saving the address for iteration
        bankAddress.push(_bankAddress) -1;
    }
    
    function incrementBankCount() internal {
        bankCount += 1;
    }


    function stringsEqual(string storage _a, string memory _b) internal view returns (bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length)
        return false;
        // @todo unroll this loop
        for (uint i = 0; i < a.length; i ++) {
            if (a[i] != b[i])
            return false;
        }
        return true;
    }
    
    function memoryStringsEqual(string memory _a, string memory _b) internal returns (bool) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length)
            return false;
            
        for (uint i = 0; i < a.length; i ++)
        {
            if (a[i] != b[i])
                return false;
        }
        return true;
    }
    
    function submitKYC(address ethAddress, string nationalID, string memory DataHash) public payable returns(string) {
        
        require(banks[msg.sender].ethAddress != address(0), "Only participating company can submit KYC");
        
        //To prevent duplicate submission from other banks
        for(uint i = 0; i < customerAddress.length; ++ i) {
            if(stringsEqual(customers[customerAddress[i]].nationalID,nationalID)){
                return "Duplicate customer submission detected";
            }
        }
        
        
        Customer storage customer = customers[ethAddress];
        customer.nationalID = nationalID;
        customer.ethAddress = ethAddress;
        customer.creatingBank = msg.sender;
        
        //Based on the nationalID, this function will call government database API and return a risk rating.
        //For this demo, we use a default risk rating of Low.
        
        customer.upvotes = 0;
        customerAddress.push(ethAddress) -1;
        customer.riskRating = Risk.Low;
        
        return "Customer Registered Successfully and initial KYC completed through government database verification";
    
        
    }


    function updateKYC(string memory nationalID, bool ifIncrease) public payable returns(string[])
    {
        
        require(customers[getCustomerAddress(nationalID)].ethAddress != address(0), "No such customer. Please register customer first.");
        Customer storage customer = customers[getCustomerAddress(nationalID)];
        if(ifIncrease) {
            customerKYCUpdateHistory[getCustomerAddress(nationalID)].push(KYCUpdateHistory(now,nationalID,getCustomerAddress(nationalID),msg.sender));
            updateHistoryaddress.push(msg.sender) -1;
            customer.upvotes ++;
            
            
        }
        else {
            string[] memory bankname = new string[](updateHistoryaddress.length +1);
            for(uint i = 0; i < updateHistoryaddress.length; ++ i) {
                bankname[i]=getBankName(updateHistoryaddress[i]);
            }
            
            //To add the originating bank for notification purpose
            bankname[bankname.length-1] = getBankName(customers[getCustomerAddress(nationalID)].creatingBank);
            customerKYCUpdateHistory[getCustomerAddress(nationalID)].push(KYCUpdateHistory(now,nationalID,getCustomerAddress(nationalID),msg.sender));
            customer.upvotes --;
            return(bankname);
            
        }

    }
    
    // Function to return the address of the customer given nationalID
    function getCustomerAddress(string nationalID) public payable returns(address) {
        for(uint i = 0; i < customerAddress.length; ++ i) {
            if(stringsEqual(customers[customerAddress[i]].nationalID, nationalID)) {
                return customerAddress[i];
            }
        }
        return 0x0;
    }
    
    // Function to return the address of the bank, given the bank name
    function getBankAddress(string uname) public payable returns(address) {
        for(uint i = 0; i < bankAddress.length; ++ i) {
            if(stringsEqual(banks[bankAddress[i]].name, uname)) {
                return bankAddress[i];
            }
        }
        return 0x0;
    }
    // Function to return the address of the bank given wallet address
    function getBankName(address ethAddress) public payable returns(string) {
        for(uint i = 0; i < bankAddress.length; ++ i) {
            
            if(banks[bankAddress[i]].ethAddress == ethAddress) {
                return banks[bankAddress[i]].name;
            }
        }
    }

    
    function viewCustomer(address accAddress) public payable returns(address,string, string,address,address,Risk) {
        Customer storage customer = customers[accAddress];
        return (customer.ethAddress, customer.nationalID, customer.dataHash, customer.lastRequestingBank, customer.creatingBank, customer.riskRating);
    }


    function viewAllCustomers() public payable returns(string[], address[], uint[], Risk[]) {
        string[] memory nationalID = new string[](customerAddress.length);
        address[] memory ethAddress = new address[](customerAddress.length);
        uint[] memory upvotes = new uint[](customerAddress.length);
        Risk[] memory riskRating = new Risk[](customerAddress.length);
        
        for(uint i = 0; i < customerAddress.length; ++ i) {
            nationalID[i]=customers[customerAddress[i]].nationalID;
            ethAddress[i]=customers[customerAddress[i]].ethAddress;
            upvotes[i]=customers[customerAddress[i]].upvotes;
            riskRating[i]=customers[customerAddress[i]].riskRating;
        }
        return(nationalID, ethAddress, upvotes, riskRating);
    }


    function viewAllBanks() public payable returns(string[], uint[]) {
        string[] memory name = new string[](bankAddress.length);
        uint[] memory KYC_count = new uint[](bankAddress.length);
        
        for(uint i = 0; i < bankAddress.length; ++ i) {
            name[i]=banks[bankAddress[i]].name;
            KYC_count[i]=banks[bankAddress[i]].KYC_count;
        }
        return(name, KYC_count);
    }   
}
