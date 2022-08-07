import Raigor
import StoreKit

public protocol TransactionVerifying {
    var logger: Logger { get }
    func processTransaction(given verificationResult: VerificationResult<Transaction>) async
    @MainActor func processVerifiedTransaction(_ verifiedTransaction: Transaction)
}

public extension TransactionVerifying {
    func processTransaction(given verificationResult: VerificationResult<Transaction>) async {
        switch verificationResult {
        case .verified(let verifiedTransaction):
            await processVerifiedTransaction(verifiedTransaction)
            await verifiedTransaction.finish()
        case .unverified(let unverifiedTransaction, let error):
            logger.error(error)
            await unverifiedTransaction.finish()
        }
    }
}
