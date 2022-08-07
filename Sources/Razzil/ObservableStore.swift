import Combine
import Raigor
import StoreKit

public enum StoreState: Equatable {
    case initial
    case loading
    case loaded
    case failed
}

public protocol ObservableStore: ObservableObject, TransactionVerifying {
    static var shared: Self { get }

    var logger: Logger { get }
    var state: StoreState { get set }

    init(logger: Logger)

    func setup()
    
    func restore()

    func processVerifiedTransaction(_ verifiedTransaction: Transaction)
}

public extension ObservableStore {
    func restore() {
        Task { try await AppStore.sync() }
    }
}
