//SPDX-License-Identifier: MIT
pragma solidity 0.8;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
//Custom errors
error TX_NOT_SUCCESSFULL();
error Lottery__UpkeepNotNeededYet(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);
error NotEnoughEth();
error Lottery__TransferFailed();
error Lottery__LotteryNotOpen();
error Lottery__SendMoreToEnterLottery();

contract Lottery is VRFConsumerBaseV2,AutomationCompatibleInterface{
    enum LotteryState {
        OPEN,
        CALCULATING
    }
    // Lottery Variables
    address public manager;
    address payable[] public players;
    LotteryState private s_lotteryState;
    uint256 private s_lastTimeStamp;
    address private recentWinner;
    uint private immutable i_interval;
    // Chainlink VRF Variables
    bytes32 private immutable i_gaslane;
    uint64 private immutable i_subscriptionId;
    uint16 constant REQUEST_CONFORMATIONS = 3;
    uint32 private immutable i_callbackGaslimit;
    uint32 private constant NUM_WORDS = 1;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    //Events
    event EnterLottery(address indexed player);
    event RequestedLotteryWinner(uint256 requestId);
    event WinnerPicked(address indexed winneraddress);

    constructor(
        address vrfCoordinatorV2,
        bytes32 keyhash,
        uint64 subscriptionId,
        uint32 callbackGaslimit,
        uint interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        manager = msg.sender;
        i_gaslane = keyhash;
        i_subscriptionId = subscriptionId;
        i_callbackGaslimit = callbackGaslimit;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_interval = interval;
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function enter() public payable {
        require(msg.value > .001 ether); //For validation
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__LotteryNotOpen();
        }
        players.push(payable(msg.sender));
        emit EnterLottery(msg.sender);
    }

    //Using chainlinkVRFv2 to generate truly random number
    /*   function requestRandomWinner() external {
        //Request the random number
        // Once we get it, do something with it
        // 2 transaction process
        uint256 winnerid = i_vrfCoordinator.requestRandomWords(
            i_gaslane,
            i_subscriptionId,
            REQUEST_CONFORMATIONS,
            i_callbackGaslimit,
            NUM_WORDS
        );
        emit RequestedLotteryWinner(winnerid);

         */ // (bool succes,)=
    // }

    // function random() private view returns (uint) {
    //     return
    //         uint(
    //             keccak256(
    //                 abi.encodePacked(block.difficulty, block.timestamp, players)
    //             )
    //         );
    // }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory _randomWords
    ) internal override {
        uint256 indexofwinner = _randomWords[0] % players.length;
        address payable recent_Winner = players[indexofwinner];
        recentWinner = recent_Winner;
        players = new address payable[](0);
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) revert TX_NOT_SUCCESSFULL();
        emit WinnerPicked(recentWinner);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between Lottery runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = LotteryState.OPEN == s_lotteryState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0"); // can we comment this out?
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotNeededYet(
                address(this).balance,
                players.length,
                uint256(s_lotteryState)
            );
        }
        s_lotteryState = LotteryState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gaslane,
            i_subscriptionId,
            REQUEST_CONFORMATIONS,
            i_callbackGaslimit,
            NUM_WORDS
        );
        emit RequestedLotteryWinner(requestId);
    }

    /* function pickWinner() public payable restricted returns (uint) {
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
        return (index);
    } */

    //The function pickWinner is replaced by performUpKeep()

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getlotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFORMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return recentWinner;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return players[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return players.length;
    }
}
