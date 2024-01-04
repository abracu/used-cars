// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

W
W
E
E
E
E
E
E
E

contract UsedCars {
    uint public price;
    address payable public seller;
    address payable public buyer;

    address[] previousBuyers;

    enum State {
        Sale,
        Locked,
        Release,
        Closed,
        Complete
    }

    State public state;

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this.");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this.");
        _;
    }

    modifier notSeller() {
        require(msg.sender != seller, "Seller shouldn't call this.");
        _;
    }

    modifier inState(State _state) {
        require(state == _state, "Invalid state.");
        _;
    }

    event Closed(uint256 when);
    event ConfirmPurchase(uint256 when, address by);
    event ConfirmReceived(uint256 when, address by);
    event SellerRefundBuyer(uint256 when);
    event SellerRefunded(uint256 when);
    event Restarted(uint256 when);
    event End(uint256 when);

    constructor() payable {
        price = msg.value / 2;
        require((2 * price) == msg.value, "Value must be even.");

        seller = payable(msg.sender);
        state = State.Sale;
    }

    function close() public onlySeller inState(State.Sale) {
        state = State.Closed;
        seller.transfer(address(this).balance);

        emit Closed(block.timestamp);
    }

    function confirmPurchase()
        public
        payable
        notSeller
        inState(State.Sale)
        condition(msg.value == (2 * price))
    {
        buyer = payable(msg.sender);
        state = State.Locked;

        emit ConfirmPurchase(block.timestamp, buyer);
    }

    function confirmReceived() public onlyBuyer inState(State.Locked) {
        state = State.Release;

        buyer.transfer(price); // Buyer receives 1 x price here
        emit ConfirmReceived(block.timestamp, buyer);
    }

    function refundBuyer() public onlySeller inState(State.Locked) {
        state = State.Sale;
        buyer = payable(0);

        emit SellerRefundBuyer(block.timestamp);
    }

    function refundSeller() public onlySeller inState(State.Release) {
        state = State.Complete;
        seller.transfer(3 * price);
        previousBuyers.push(buyer);

        emit SellerRefunded(block.timestamp);
    }

    function restartContract() public payable onlySeller {
        if (state == State.Closed || state == State.Complete) {
            require(
                (2 * price) == msg.value,
                "Value has to be equal to what started the contract."
            );

            state = State.Sale;
            buyer = payable(0);

            emit Restarted(block.timestamp);
        }
    }

    function listPreviousBuyers() public view returns (address[] memory) {
        return previousBuyers;
    }

    function totalSales() public view returns (uint count) {
        return previousBuyers.length;
    }

    function end() public onlySeller {
        if (state == State.Closed || state == State.Complete) {
            emit End(block.timestamp);

            selfdestruct(seller);
        }
    }
}
