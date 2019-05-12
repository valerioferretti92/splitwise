pragma solidity ^0.5.0;

contract SplitwiseGroup {

  uint256 private idCounter = 1;

  struct Group {
    string title;
    address[] participants;
    bool isDeleted;
    bool isActive;
  }

  struct GroupProposal {
    string title;
    address[] proposedParticipants;
    address[] confirmations;
    address[] cancellations;
    mapping(address => bool) voteLedger;
    bool isRejected;
    bool isApproved;
  }

  address deployer;

  mapping(uint256 => GroupProposal) private groupProposals;

  mapping(uint256 => Group) private groups;

  mapping(address => bool) addressLedger;

  constructor() public {
    deployer = msg.sender;
  }

  modifier deployer_only {
    require(msg.sender == deployer, "Only the deployer of the contract can invoke its functions!");
    _;
  }

  function registerGroupProposal(string calldata title, address[] calldata participants) external returns(uint256, address[] memory){
    require(participants.length >= 2);
    require(participants.length <= 50);

    uint256 groupId = idCounter++;
    for(uint8 i = 0; i < participants.length; i++){
      if(!addressLedger[participants[i]]){
        groupProposals[groupId].proposedParticipants.push(participants[i]);
        addressLedger[participants[i]] = true;
      }
    }
    groupProposals[groupId].title = title;
    groupProposals[groupId].isRejected = false;
    groupProposals[groupId].isApproved = false;

    cleanUpAddressLedger(groupProposals[groupId].proposedParticipants);
    return(groupId, groupProposals[groupId].proposedParticipants);
  }

  function submitUserParticipation(uint256 groupProposalId, bool confirmation) external
    returns(uint256, address[] memory, address[] memory, address[] memory, bool, bool){
    //Checking that group proposal has not been discarded or transformed into a group already
    require(!groupProposals[groupProposalId].isRejected, "Already rejected group proposal");
    require(!groupProposals[groupProposalId].isApproved, "Already approved group proposal");
    require(!groupProposals[groupProposalId].voteLedger[tx.origin], "Double voting is not allowed");

    //Registering confirmation or cancellation
    return registerUserParticipation(groupProposalId, confirmation);
  }

  function deleteGroup(uint256 groupId) external returns(address[] memory){
    groups[groupId].isDeleted = true;
    groups[groupId].isActive = false;

    return groups[groupId].participants;
  }

  /*************** GETTER FUNCTIONS ****************/

  function getGroup(uint256 groupId) external view returns(string memory, address[] memory) {
    bool isDeleted = groups[groupId].isDeleted;
    bool isActive = groups[groupId].isActive;
    require(isActive && !isDeleted, "The group is either not active or deleted");
    return (groups[groupId].title, groups[groupId].participants);
  }

  function getGroupProposal(uint256 groupProposalId) external view
    returns (string memory, address[] memory, address[] memory, address[] memory) {
      GroupProposal memory gp = groupProposals[groupProposalId];
      return (gp.title, gp.proposedParticipants, gp.confirmations, gp.cancellations);
  }

  /*************** PRIVATE FUNCTIONS ****************/

  function cleanUpAddressLedger(address[] memory proposedParticipants) private {
    for(uint8 i = 0; i < proposedParticipants.length; i++){
      delete addressLedger[proposedParticipants[i]];
    }
  }

  function registerUserParticipation(uint256 id, bool confirmation) private
    returns(uint256, address[] memory, address[] memory, address[] memory, bool, bool){
    if(confirmation) groupProposals[id].confirmations.push(tx.origin);
    if(!confirmation) groupProposals[id].cancellations.push(tx.origin);
    groupProposals[id].voteLedger[tx.origin] = true;

    //Checking wheater it is necessary to create a new group
    bool isGroupCreated = false;
    bool isGroupProposalCancelled = false;
    GroupProposal memory gp = groupProposals[id];
    if(gp.cancellations.length >= gp.proposedParticipants.length - 1){
      deleteGroupProposal(id);
      isGroupCreated =  false;
      isGroupProposalCancelled = true;
    }else if(gp.confirmations.length + gp.cancellations.length == gp.proposedParticipants.length){
      registerNewGroup(id, gp.confirmations, gp.title);
      isGroupCreated =  true;
      isGroupProposalCancelled = false;
    }
    return (id, gp.proposedParticipants, gp.confirmations, gp.cancellations, isGroupCreated, isGroupProposalCancelled);
  }

  function registerNewGroup(uint256 groupId, address[] memory participants, string memory title) private returns(uint256){
    groups[groupId].participants = participants;
    groups[groupId].title = title;
    groups[groupId].isDeleted = false;
    groups[groupId].isActive = true;
    groupProposals[groupId].isApproved = true;
    return groupId;
  }

  function deleteGroupProposal(uint256 groupProposalId) private returns(uint256){
    groupProposals[groupProposalId].isRejected = true;
    return groupProposalId;
  }
}
