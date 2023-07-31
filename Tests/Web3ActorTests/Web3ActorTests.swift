import XCTest
@testable import Web3Actor

final class Web3ActorTests: XCTestCase {
    func testExample() async throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let contracts = await Web3Actor.shared.getContracts()
        XCTAssertEqual(contracts, [])
    }
}
