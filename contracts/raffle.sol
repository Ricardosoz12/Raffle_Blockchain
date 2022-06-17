import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Raffle is VRFConsumerBase {
    address public owner;
    address payable[] public players;
    uint public RaffleId;
    mapping (uint => address payable) public RaffleHistory;

    bytes32 internal keyHash; // identifies which Chainlink oracle to use
    uint internal fee;        // fee to get random number
    uint public randomResult;

    constructor()
        VRFConsumerBase(
            //----------RINKEBY DATA----------
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK
        ) {
            keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
            fee = 0.1 * 10 ** 18;    // 0.1 LINK

            owner = msg.sender;
            RaffleId = 1;
        }

    /** 
     * Solicitudes de aleatoriedad
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "No hay suficiente LINK para concretar la operación");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Función callback utilizada por VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
        randomResult = randomness;
        payWinner();
    }

    /**
     * Función para obetener el ganador de la rifa
     */
    function getWinnerByRaffle(uint Raffle) public view returns (address payable) {
        return RaffleHistory[Raffle];
    }

    /**
     * Función para obetener el balance de la rifa
     */
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    /**
     * Función para obtener los jugadores
     */
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    /**
     * Función para meter participantes
     */

    function enter() public payable {
        require(msg.value > .01 ether);

        // address del participante 
        players.push(payable(msg.sender));
    }

    /**
     * Función para obtener ganador
     */
    function pickWinner() public onlyowner {
        getRandomNumber();
    }

    /**
     * Función para pagarle al ganador
     */
    function payWinner() public {
        uint index = randomResult % players.length;
        players[index].transfer(address(this).balance);

        RaffleHistory[RaffleId] = players[index];
        RaffleId++;
        
        // restaurar el estado del sc
        players = new address payable[](0);
    }

    modifier onlyowner() {
        require(msg.sender == owner);
         _;
    }
}