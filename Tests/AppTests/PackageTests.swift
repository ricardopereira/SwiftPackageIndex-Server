import Fluent

@testable import App

import XCTVapor


final class PackageTests: XCTestCase {
    var app: Application!

    override func setUpWithError() throws {
        app = try setup(.testing)
    }

    override func tearDownWithError() throws {
        app.shutdown()
    }

    func test_encode() throws {
        let p = Package(id: UUID(), url: URL(string: "https://github.com/finestructure/Arena")!)
        p.lastCommitAt = Date()
        let data = try JSONEncoder().encode(p)
        XCTAssertTrue(!data.isEmpty)
    }

    func test_decode() throws {
        let timestamp: TimeInterval = 609426189  // Apr 24, 2020, just before 13:00 UTC
                                                 // Date.timeIntervalSinceReferenceDate
        let json = """
        {
            "id": "CAFECAFE-CAFE-CAFE-CAFE-CAFECAFECAFE",
            "url": "https://github.com/finestructure/Arena",
            "lastCommitAt": \(timestamp)
        }
        """
        let p = try JSONDecoder().decode(Package.self, from: Data(json.utf8))
        XCTAssertEqual(p.id?.uuidString, "CAFECAFE-CAFE-CAFE-CAFE-CAFECAFECAFE")
        XCTAssertEqual(p.url, "https://github.com/finestructure/Arena")
        XCTAssertEqual(p.lastCommitAt?.description, "2020-04-24 13:03:09 +0000")
    }

    func test_unique_url() throws {
        try Package(url: "p1".url).save(on: app.db).wait()
        XCTAssertThrowsError(try Package(url: "p1".url).save(on: app.db).wait())
    }

    func test_filter_by_url() throws {
        try ["https://foo.com/1", "https://foo.com/2"].forEach {
            try Package(url: $0.url).save(on: app.db).wait()
        }
        let res = try Package.query(on: app.db).filter(by: "https://foo.com/1".url).all().wait()
        XCTAssertEqual(res.map(\.url), ["https://foo.com/1"])
    }

    // TODO: move to other test
    func test_apiUri() throws {
        do {
            let pkg = Package(url: "https://github.com/SwiftPackageIndex/SwiftPackageIndex-Server.git".url)
            XCTAssertEqual(try Github.apiUri(for: pkg).string,
                           "https://api.github.com/repos/SwiftPackageIndex/SwiftPackageIndex-Server")
        }
        do {
            let pkg = Package(url: "https://github.com/SwiftPackageIndex/SwiftPackageIndex-Server".url)
            XCTAssertEqual(try Github.apiUri(for: pkg).string,
                           "https://api.github.com/repos/SwiftPackageIndex/SwiftPackageIndex-Server")
        }
    }
}

