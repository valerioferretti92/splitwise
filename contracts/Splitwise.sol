pragma solidity ^0.5.0;

import "./SplitwiseGroup.sol";

contract Splitwise {

  SplitwiseGroup swGroup;

  mapping(address => uint256[]) userGroups;
  mapping(address => uint256[]) userGroupProposals;

  constructor(address splitwiseGroupAddress) public {
    swGroup = SplitwiseGroup(splitwiseGroupAddress);
  }

  function initSplitwiseGroup() external {
    address deployer = swGroup.init();
    emit SplitwiseGroupDeployerRegistered(deployer);
  }

  function registerGroupProposal(string calldata title, address[] calldata desiredParticipants) external {
    uint256 groupProposalId;
    address[] memory participants;

    (groupProposalId, participants) = swGroup.registerGroupProposal(title, desiredParticipants);
    for(uint8 i = 0; i < participants.length; i++)
      userGroupProposals[participants[i]].push(groupProposalId);

    emit GroupProposalSubmitted(groupProposalId, participants);
  }

  function submitUserParticipation(uint256 groupProposalId, bool confirmation) external {
    uint256 id;
    address[] memory proposedParticipants;
    address[] memory confirmations;
    address[] memory cancellations;
    bool isGroupCreated;
    bool isGroupProposalCancelled;

    uint8 index = getGroupIndex(groupProposalId, userGroupProposals[msg.sender]);
    require(index < userGroupProposals[msg.sender].length, "Not a group participant");

    (id, proposedParticipants, confirmations, cancellations, isGroupCreated, isGroupProposalCancelled)
      = swGroup.submitUserParticipation(groupProposalId, confirmation);

    if(!confirmation) userGroupProposals[msg.sender] = removeGroupByIndex(index, userGroupProposals[msg.sender]);
    if(!isGroupCreated && !isGroupProposalCancelled) {
      emit UserParticipantionRegistered(id, proposedParticipants, confirmations, cancellations);
    }else if(!isGroupCreated && isGroupProposalCancelled) {
      deleteGroupProposal(id, proposedParticipants);
      emit GroupProposalDeleted(id, proposedParticipants, confirmations, cancellations);
    }else if(isGroupCreated && !isGroupProposalCancelled){
      deleteGroupProposal(id, proposedParticipants);
      registerNewGroup(id, confirmations);
      emit GroupCreated(id, proposedParticipants, confirmations, cancellations);
    }else revert();
  }

  function deleteGroup(uint256 groupId) external {
    uint8 index = getGroupIndex(groupId, userGroupProposals[msg.sender]);
    require(index < userGroupProposals[msg.sender].length, "Not a group participant");

    address[] memory participants = swGroup.deleteGroup(groupId);
    for(uint8 i = 0; i < participants.length; i++){
      index = getGroupIndex(groupId, userGroupProposals[participants[i]]);
      userGroupProposals[participants[i]] = removeGroupByIndex(index, userGroupProposals[participants[i]]);
    }
    emit GroupDeleted(groupId, participants);
  }

  /*************** GETTER FUNCTIONS ****************/

  function getUserGroups() external view returns(uint256[] memory){
    return userGroups[msg.sender];
  }

  function getGroup(uint256 groupId) external view returns(string memory, address[] memory){
    uint8 index = getGroupIndex(groupId, userGroups[msg.sender]);
    require(index < userGroups[msg.sender].length, "The specified group is not associated to msg.sender");
    return swGroup.getGroup(groupId);
  }

  function getUserGroupProposals() external view returns(uint256[] memory){
    return userGroupProposals[msg.sender];
  }

  function getGroupProposal(uint256 groupProposalId) external view
    returns (string memory, address[] memory, address[] memory, address[] memory){
    uint8 index = getGroupIndex(groupProposalId, userGroupProposals[msg.sender]);
    require(index < userGroupProposals[msg.sender].length, "The specified group proposal is not associated to msg.sender");
    return swGroup.getGroupProposal(groupProposalId);
  }

  /*************** PRIVATE FUNCTIONS ****************/

  function deleteGroupProposal(uint256 groupProposalId, address[] memory users) private {
    uint8 index;

    for(uint8 i = 0; i < users.length; i++){
      index = getGroupIndex(groupProposalId, userGroupProposals[users[i]]);
      if(index < userGroupProposals[users[i]].length)
        userGroupProposals[users[i]] = removeGroupByIndex(index, userGroupProposals[users[i]]);
    }
  }

  function registerNewGroup(uint256 groupId, address[] memory users) private {
    for(uint8 i = 0; i < users.length; i++){
      userGroups[users[i]].push(groupId);
    }
  }

  /*************** EVENTS ****************/

  event SplitwiseGroupDeployerRegistered(address deployer);

  event GroupProposalSubmitted(uint256 groupId, address[] proposedParticipants);

  event UserParticipantionRegistered(uint256 groupId, address[] proposedParticipants, address[] confirmations, address[] cancellations);

  event GroupProposalDeleted(uint256 groupId, address[] proposedParticipants, address[] confirmations, address[] cancellations);

  event GroupCreated(uint256 groupId, address[] proposedParticipants, address[] confirmations, address[] cancellations);

  event GroupDeleted(uint256 groupId, address[] participants);

  /*************** LIBRARY FUNCTIONS ****************/

  function getGroupIndex(uint256 groupId, uint256[] memory groups) private pure returns(uint8){
    for(uint8 i = 0; i < groups.length; i++){
      if(groupId == groups[i]) return i;
    }
    return uint8(groups.length);
  }

  function removeGroupByIndex(uint index, uint256[] memory groups) private pure returns(uint256[] memory) {
        if (index >= groups.length) return groups;

        uint256[] memory newGroups = new uint256[](groups.length - 1);
        for (uint8 i = 0; i < groups.length; i++){
            if(i < index) newGroups[i] = groups[i];
            if(i > index) newGroups[i - 1] = groups[i];
        }
        return newGroups;
  }
}
