import XCTest
@testable import TMDB_Shared_Backend

final class AccountTests: XCTestCase {
    func testAccountParsing() throws {
        let bundle = Bundle.module
        let url = try XCTUnwrap(bundle.url(forResource: "accounts", withExtension: "json"))
        let data = try XCTUnwrap(try Data(contentsOf: url))
        
        var account: AccountInfoModel?
        XCTAssertNoThrow(account = try JSONDecoder().decode(AccountInfoModel.self, from: data))
        
        let unwrappedAccount = try XCTUnwrap(account)
        XCTAssertEqual(unwrappedAccount.id, 22222)
        XCTAssertEqual(unwrappedAccount.iso_639_1, "en")
        XCTAssertEqual(unwrappedAccount.iso_3166_1, "CA")
        XCTAssertEqual(unwrappedAccount.username, "user1")
        XCTAssertFalse(unwrappedAccount.include_adult)
    }
} 
