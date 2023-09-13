import XCTest
import Web3
@testable import Web3Actor

final class Web3ActorTests: XCTestCase {
    func testExample() async throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let contracts = await Web3Actor.shared.getContracts()
        XCTAssertEqual(contracts, [])
    }
    
    func testOpensea() async throws {
        await Web3Actor.shared.initialize(.EthereumGoerli, openseaApiKey: "c823fdee93814f7abd5492604697e9c8")
        guard let address = EthereumAddress(hexString: "0x85fD692D2a075908079261F5E351e7fE0267dB02") else { return }
        var cursor = try await Web3Actor.shared.getNFTs(of: address)
        while cursor != nil {
            cursor = try await Web3Actor.shared.getNFTs(of: address, nextCursor: cursor)
        }
    }
}
