pragma solidity ^0.5.0;

contract Splitwise {

  uint256 private idCounter = 1;

  struct Group {
    address[] participants;
    mapping(address => mapping(address => uint256)) balances;
    bool isSettledUp;
  }

  struct GroupProposal {
    address[] participants;
    mapping(address => bool) confirmations;
    mapping(address => bool) addressLedger;
    bool isRejected;
    bool isApproved;
  }

  mapping(uint256 => GroupProposal) private groupProposals;

  mapping(uint256 => Group) private groups;

  function registerGroupProposal(address[] calldata participants) external {
    require(participants.length >= 2);
    require(participants.length <= 50);

    uint256 groupProposalId = idCounter++;
    for(uint8 i = 0; i < participants.length; i++){
      if(!groupProposals[groupProposalId].addressLedger[participants[i]]){
        groupProposals[groupProposalId].participants.push(participants[i]);
        groupProposals[groupProposalId].addressLedger[participants[i]] = true;
        groupProposals[groupProposalId].confirmations[participants[i]] = false;
      }
    }
    groupProposals[groupProposalId].isRejected = false;
    groupProposals[groupProposalId].isApproved = false;

    emit GroupProposalSubmitted(groupProposalId, groupProposals[groupProposalId].participants);
  }

  function registerGroupConfirmation(uint256 groupId, bool confirmation) external {
    //Checking that group proposal has not been discarded or transformed into a group already
    require(!groupProposals[groupId].isRejected, "Already rejected group proposal");
    require(!groupProposals[groupId].isApproved, "Already approved group proposal");

    //Checking that sender is an invited group participant
    uint8 index = getParticipantIndex(groupProposals[groupId].participants, msg.sender);
    require(index < groupProposals[groupId].participants.length, "Not a group participant");

    //Checking whether sender does not intend to be part of the group
    if(!confirmation) {
      groupProposals[groupId].participants = removeParticipantByIndex(groupProposals[groupId].participants, index);
      groupProposals[groupId].confirmations[msg.sender] = false;
      emit GroupConfirmationRegistered(groupId, msg.sender);
      if(groupProposals[groupId].participants.length < 2){
        groupProposals[groupId].isRejected = true;
        emit GroupProposalDeleted(groupId);
      }
      return;
    }
    groupProposals[groupId].confirmations[msg.sender] = true;
    emit GroupConfirmationRegistered(groupId, msg.sender);

    //Checking wheater it is necessary to create a new group
    if(getGroupProposalConfirmationCount(groupProposals[groupId]) == groupProposals[groupId].participants.length){
      groups[groupId].participants = groupProposals[groupId].participants;
      groups[groupId].isSettledUp = true;
      groupProposals[groupId].isApproved = true;
      emit GroupCreated(groupId, groups[groupId].participants);
    }
  }

  function getGroupProposalConfirmationCount(GroupProposal storage groupProposal) private view returns(uint8){
    uint8 counter = 0;
    for(uint8 i = 0; i < groupProposal.participants.length; i++){
      address participant = groupProposal.participants[i];
      if(groupProposal.confirmations[participant]) counter++;
    }
    return counter;
  }

  function getParticipantIndex(address[] memory participants, address sender) private pure returns(uint8){
    for(uint8 i = 0; i < participants.length; i++){
      if(sender == participants[i]) return i;
    }
    return uint8(participants.length);
  }

  function removeParticipantByIndex(address[] memory participants, uint index) private pure returns(address[] memory) {
        if (index >= participants.length) return participants;

        address[] memory newParticipants = new address[](participants.length - 1);
        for (uint8 i = 0; i < participants.length; i++){
            if(i < index) newParticipants[i] = participants[i];
            if(i > index) newParticipants[i - 1] = participants[i];
        }
        delete participants;
        return newParticipants;
  }

  event GroupProposalSubmitted(uint256 groupId, address[] participants);

  event GroupConfirmationRegistered(uint256 groupId, address participant);

  event GroupCreated(uint256 groupId, address[] participants);

  event GroupProposalDeleted(uint256 groupId);
}
