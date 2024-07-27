// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


contract Fundme{
    // detailed campaign with name, target, deadline, completed, funders
    // create a campaign
    // add funds
    // who has funded
    // withdraw funds
    
    struct Campaign{
        string name;
        string image;
        address owner;
        uint256 funds_target;
        uint256 funds_deposited;
        uint256 deadline;
        bool completed;
        address[]  funders;
        bool withdrawalDone;
    }
    event fundTransferEvent(uint256 index,address from , bool success);
    event withdrawFundsEvent(uint256 index, address to, bool sucess);
    event createCampaignEvent(bool success);

    Campaign[] public allCamapaigns;
    function numOfCampaigns() public view returns(uint){
        return allCamapaigns.length;
    }
    address immutable owner;
    AggregatorV3Interface internal datafeed;

    constructor(){
        owner = msg.sender;
        datafeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306  
        );
    }

    function priceConverter(uint256 ethAmount) public view returns(uint256){
        (,int answer,,,) = datafeed.latestRoundData();
        return (ethAmount * uint(answer))/10**8;
    }
    function getCampaigns() public view returns(Campaign[] memory _allCamapaigns){
        return allCamapaigns;
    }
    
    modifier onlyOwner(){
        require(msg.sender==owner,"Can only be withdrawn by the owner");
        _;
    }
    uint256 public time;
    function createCampaign(string memory _name,string memory _image,uint256 _funds_target) public {
        address[] memory contractfunders;
        time = block.timestamp + 7 days;
        Campaign memory campaign = Campaign(_name , _image,msg.sender ,_funds_target,0,time,false,contractfunders,false); 
        allCamapaigns.push(campaign);
        emit createCampaignEvent(true);
    }

    function fundContract(uint256 _index) public payable {
        require(priceConverter(msg.value)>=5e18,"Not Enough Token");
        Campaign storage currentCampaign = allCamapaigns[_index];
        currentCampaign.funds_deposited = currentCampaign.funds_deposited + msg.value;
        currentCampaign.funders.push(msg.sender);
        if(currentCampaign.deadline <= block.timestamp || currentCampaign.funds_target<= currentCampaign.funds_deposited){
            currentCampaign.completed = true;
        }
        emit fundTransferEvent(_index, msg.sender, true);
    }

    function withdrawFunds(uint256 _index) public payable onlyOwner {
        uint256 deposited_value = allCamapaigns[_index].funds_deposited;
        (bool success,) = payable(allCamapaigns[_index].owner).call{value:deposited_value}("");
        require(success,"Withdrawal failed");
        allCamapaigns[_index].funds_deposited = 0;
        allCamapaigns[_index].completed = true;
        allCamapaigns[_index].withdrawalDone = true;
        emit withdrawFundsEvent(_index, msg.sender, true);
    }
}