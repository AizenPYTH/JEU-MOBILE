/// Things that happened during a simulation step. The presentation drains them to
/// play animations and sounds; analytics can listen to them too. Never saved.
public enum GameEvent: Sendable, Equatable {
    case customerArrived(tableIndex: Int, customerID: CustomerID)
    case orderPlaced(Order)
    case preparationStarted(station: StationID, order: Order)
    case dishReady(station: StationID, order: Order)
    case dishServed(Order)
    case customerPaid(tableIndex: Int, price: Int, tip: Int)
    case coinsCollected(tableIndex: Int, amount: Int, automatic: Bool)
    case stationBoosted(StationID)
    case menuChanged
}
