import Foundation
@testable import Core

extension ProcessResult {
    static func stub(terminationStatus: Int32 = 0, output: String = "") -> Self {
        ProcessResult(
            terminationStatus: terminationStatus,
            output: Data(output.utf8)
        )
    }
}
