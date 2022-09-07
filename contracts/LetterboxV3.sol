//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

//edit outs - things that do not appear necessary

import "@openzeppelin/contracts/utils/Counters.sol";
import "./RMRK/RMRKMultiResource.sol";

contract LetterboxV3 is RMRKMultiResource {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdAuto;
    Counters.Counter private _resourceIdAuto;

    uint256 private _mintFee;
    bool private paused;
    address private _admin;

    //this is a list of letterbox IDs that exist.
    uint256[] letterboxlist;

    //which Ids exist as letterboxes held by users
    struct OwnedLetterboxesInfo {
        uint256[] letterboxIds;
    }
    //mapping connecting an address to Letterbox
    mapping(address => OwnedLetterboxesInfo) internal letterboxesToAddresses;

    // this is to a uint256 and not array because stamp to address should be 1:1 relationship
    mapping(address => uint256) internal stampsToAddresses;

    constructor(string memory name, string memory symbol)
        RMRKMultiResource(name, symbol)
    {
        paused = false;
        _admin = msg.sender;
        _mintFee = 0;
        _resourceIdAuto.increment(); //resource cannot be at index 0 per standard
        _tokenIdAuto.increment();
    }

    event contractPaused()

    function mapLetterboxAddr(address to_, uint256 tokenId_) private {
        letterboxesToAddresses[to_].letterboxIds.push(tokenId_);
    }

    function mapStampAddr(address to_, uint tokenId_) private {
        //ATTENTION - review and remove commented section here
        //modifier on caller function should be isStampEligible
        // require(
        //     stampsToAddresses[to_] == 0,
        //     "address already has stamp, do not mint"
        // );

        stampsToAddresses[to_] = tokenId_;
    }

    function stampHeldBy(address owner) public view returns (uint256) {
        return stampsToAddresses[owner];
    }

    function letterboxesHeldBy(address owner)
        public
        view
        returns (uint256[] memory)
    {
        //ATTENTION - review and remove or update
        // require(
        //     letterboxesToAddresses[owner].letterboxIds[0] > 0,
        //     "user has not minted letterbox"
        // );

        return letterboxesToAddresses[owner].letterboxIds;
    }

    function letterboxList() public view returns (uint256[] memory) {
        return letterboxlist;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Not authorized for this action");
        _;
    }

    modifier isStampEligible(address to_) {
        //need to cehck to see if address already owns one.
        require(stampHeldBy(to_) == 0, "Only one stamp per address");
        _;
    }

    modifier isNotPaused() {
        require(paused == false, "no minting is permitted at this time");
        _;
    }

    function hasStamp(address owner) public view returns (bool) {
        if (stampHeldBy(owner) == 0) {
            return false;
        } else {
            return true;
        }
    }

    function stampMetadataURI(address owner)
        public
        view
        returns (string memory)
    {
        RMRKMultiResource _multiResource;
        if (hasStamp(owner) == true) {
            Resource[] memory stamp = _multiResource.getFullResources(
                stampHeldBy(owner)
            );
            return stamp[0].metadataURI;
        } else {
            return "User does not have stamp";
        }
    }

    function letterboxMetadataURI(uint256 letterboxTokenId)
        public
        view
        returns (string memory, uint64)
    {
        //ATTENTION add try catch
        RMRKMultiResource _multiResource;

        Resource[] memory letterbox = _multiResource.getFullResources(
            letterboxTokenId
        );
        (string memory metadata, uint64 id) = (
            letterbox[0].metadataURI,
            letterbox[0].id
        );
        return (metadata, id);
    }

    function resourceCount(uint256 tokenId_) public view returns (uint256) {
        RMRKMultiResource _multiResource;
        return _multiResource.getFullResources(tokenId_).length;
    }

    function createAndAddResource(
        uint256 tokenId_,
        string memory resourceMetadata,
        bool isAccepted
    ) internal {
        uint64 resourceId = nextResourceId();
        //appears to be deprecated with updates to RMRK code -   uint128[] memory custom;
        _addResourceEntry(resourceId, resourceMetadata);
        _addResourceToToken(tokenId_, resourceId, 0); // i believe if overwrite is 0 it will prevent from overwriting a token.

        if (isAccepted == true) {
            uint64[] memory pendingResources = getPendingResources(tokenId_);
            if (pendingResources.length >= 1) {
                uint256 tokenToApprove = pendingResources.length - 1;
                _acceptResource(tokenId_, tokenToApprove);
            } else {
                //error
            }
        }
    }

    function stampToLetterbox(
        address stampUser,
        uint256 letterboxTokenId,
        bool accepted
    ) public isNotPaused {
        string memory stampMetadata = stampMetadataURI(stampUser);
        createAndAddResource(letterboxTokenId, stampMetadata, accepted);
    }

    function letterboxToStamp(address stampUser, uint256 letterboxTokenId)
        public
        isNotPaused
    {
        //should add custom data for letterboxer to choose autoaccept
        string memory letterboxMetadata;
        (letterboxMetadata, ) = letterboxMetadataURI(letterboxTokenId);
        uint256 stampReceiving = stampHeldBy(stampUser);
        createAndAddResource(stampReceiving, letterboxMetadata, true);
    }

    //ATTENTION : needs a modifier for contract owner CHECK THIS
    //IMPORTANT SECURITY STEP! CHECK THIS!

    function withdraw() public payable {
        payable(msg.sender).transfer(address(this).balance);
    }

    function addResourceEntry(
        //  uint64 id,  change this to be _resourceIdAuto instead
        string memory metadataURI
    )
        public
        // uint128[] memory custom  //this appears deprecated in updates to RMRK code
        isNotPaused
    {
        //this is to set the variable as a uint64  - could be an issue if overflow?
        uint64 currentResource = nextResourceId();
        _addResourceEntry(currentResource, metadataURI);
        _resourceIdAuto.increment();
    }

    function nextResourceId() public view returns (uint64) {
        uint64 nextResource = uintFixerFun(_resourceIdAuto.current());
        return nextResource;
    }

    //external functions

    //ATTENTION! fee setter needs modifier to prevent anyone from using it.
    function feeSetter(uint256 newMintFee_) public {
        _mintFee = newMintFee_;
    }

    function feeGetter() public view returns (uint256) {
        return _mintFee;
    }

    //ATTENTION needs modifier to ensure only certain addresses can pause

    function pauseContract(bool state) public onlyAdmin {
        paused = state;
        emit contractPaused;
    }

    function isPaused() public view returns (bool) {
        return paused;
    }

    //hack to solve a problem, probably not a great way to handle this
    function uintFixerFun(uint256 resourceId_) private pure returns (uint64) {
        return uint64(resourceId_);
    }

    //creates a stamp with the URI passed for first (therefore primary) resource
    //automatically adds and approves the initial upload as a resource.

    function mintInitial(address to_, string memory resourceURI_)
        private
        returns (uint256)
    {
        //mint a token to accept the resource.
        uint256 tokenIdNow = _tokenIdAuto.current();
        _safeMint(to_, tokenIdNow);

        //this is an argument we need to pass with the add resource function but currently have not used

        createAndAddResource(tokenIdNow, resourceURI_, true);

        _tokenIdAuto.increment();

        //returns the tokenid used for making this token to be added to a mapping
        return tokenIdNow;
    }

    //this function is for the initial mint of the stamp for
    //those in the "finder" role.
    function mintStamp(address to_, string memory uri_)
        public
        payable
        isStampEligible(to_)
        isNotPaused
    {
        require(
            msg.value >= _mintFee,
            "Insufficient funds sent with transaction"
        );
        uint256 newTokenId;
        newTokenId = mintInitial(to_, uri_);
        mapStampAddr(to_, newTokenId);
    }

    //this function mints new letterboxes, much like new finder stamps
    //however, with no test for a charge
    function mintLetterbox(address to_, string memory uri_) public isNotPaused {
        uint256 newTokenId = mintInitial(to_, uri_);
        mapLetterboxAddr(to_, newTokenId);
        letterboxlist.push(newTokenId);
    }
}
