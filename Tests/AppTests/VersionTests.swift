@testable import App

import XCTVapor


class VersionTests: AppTestCase {
    
    func test_save() throws {
        // setup
        let pkg = try savePackage(on: app.db, "1".asGithubUrl.url)
        let v = try Version(package: pkg)
        
        // MUT - save to create
        try v.save(on: app.db).wait()
        
        // validation
        XCTAssertEqual(v.$package.id, pkg.id)
        
        v.commit = "commit"
        v.latest = .defaultBranch
        v.packageName = "pname"
        v.publishedAt = Date(timeIntervalSince1970: 1)
        v.reference = .branch("branch")
        v.releaseNotes = "release notes"
        v.supportedPlatforms = [.ios("13"), .macos("10.15")]
        v.swiftVersions = ["4.0", "5.2"].asSwiftVersions
        v.url = pkg.versionUrl(for: v.reference!)
        
        // MUT - save to update
        try v.save(on: app.db).wait()
        
        do {  // validation
            let v = try XCTUnwrap(Version.find(v.id, on: app.db).wait())
            XCTAssertEqual(v.commit, "commit")
            XCTAssertEqual(v.latest, .defaultBranch)
            XCTAssertEqual(v.packageName, "pname")
            XCTAssertEqual(v.publishedAt, Date(timeIntervalSince1970: 1))
            XCTAssertEqual(v.reference, .branch("branch"))
            XCTAssertEqual(v.releaseNotes, "release notes")
            XCTAssertEqual(v.supportedPlatforms, [.ios("13"), .macos("10.15")])
            XCTAssertEqual(v.swiftVersions, ["4.0", "5.2"].asSwiftVersions)
            XCTAssertEqual(v.url, "https://github.com/foo/1/tree/branch")
        }
    }
    
    func test_empty_array_error() throws {
        // Test for
        // invalid field: swift_versions type: Array<SemVer> error: Unexpected data type: JSONB[]. Expected array.
        // Fix is .sql(.default("{}"))
        // setup
        
        let pkg = try savePackage(on: app.db, "1")
        let v = try Version(package: pkg)
        
        // MUT
        try v.save(on: app.db).wait()
        
        // validation
        _ = try XCTUnwrap(Version.find(v.id, on: app.db).wait())
    }
    
    func test_delete_cascade() throws {
        // delete package must delete version
        // setup
        
        let pkg = Package(id: UUID(), url: "1")
        let ver = try Version(id: UUID(), package: pkg)
        try pkg.save(on: app.db).wait()
        try ver.save(on: app.db).wait()
        
        XCTAssertEqual(try Package.query(on: app.db).count().wait(), 1)
        XCTAssertEqual(try Version.query(on: app.db).count().wait(), 1)
        
        // MUT
        try pkg.delete(on: app.db).wait()
        
        // version should be deleted
        XCTAssertEqual(try Package.query(on: app.db).count().wait(), 0)
        XCTAssertEqual(try Version.query(on: app.db).count().wait(), 0)
    }
    
    func test_supportsMajorSwiftVersion() throws {
        XCTAssert(Version.supportsMajorSwiftVersion(5, value: "5".asSwiftVersion))
        XCTAssert(Version.supportsMajorSwiftVersion(5, value: "5.0".asSwiftVersion))
        XCTAssert(Version.supportsMajorSwiftVersion(5, value: "5.1".asSwiftVersion))
        XCTAssert(Version.supportsMajorSwiftVersion(4, value: "5".asSwiftVersion))
        XCTAssertFalse(Version.supportsMajorSwiftVersion(5, value: "4".asSwiftVersion))
        XCTAssertFalse(Version.supportsMajorSwiftVersion(5, value: "4.0".asSwiftVersion))
    }
    
    func test_supportsMajorSwiftVersion_values() throws {
        XCTAssert(Version.supportsMajorSwiftVersion(5, values: ["5"].asSwiftVersions))
        XCTAssertFalse(Version.supportsMajorSwiftVersion(5, values: ["4"].asSwiftVersions))
        XCTAssert(Version.supportsMajorSwiftVersion(5, values: ["5.2", "4", "3.0", "3.1", "2"].asSwiftVersions))
        XCTAssertFalse(Version.supportsMajorSwiftVersion(5, values: ["4", "3.0", "3.1", "2"].asSwiftVersions))
        XCTAssert(Version.supportsMajorSwiftVersion(4, values: ["4", "3.0", "3.1", "2"].asSwiftVersions))
    }

    func test_isBranch() throws {
        // setup
        let pkg = try savePackage(on: app.db, "1".asGithubUrl.url)
        let v1 = try Version(package: pkg, reference: .branch("main"))
        let v2 = try Version(package: pkg, reference: .tag(1, 2, 3))
        let v3 = try Version(package: pkg, reference: nil)

        // MUT & validate
        XCTAssertTrue(v1.isBranch)
        XCTAssertFalse(v2.isBranch)
        XCTAssertFalse(v3.isBranch)
    }

    func test_latestBranchVersion() throws {
        // setup
        let pkg = try savePackage(on: app.db, "1".asGithubUrl.url)
        let vid = UUID()
        let v1 = try Version(id: UUID(),
                             package: pkg,
                             commitDate: .init(timeIntervalSince1970: 0),
                             reference: .branch("main"))
        let v2 = try Version(id: UUID(),
                             package: pkg,
                             commitDate: .init(timeIntervalSince1970: 1),
                             reference: .branch("main"))
        let v3 = try Version(id: vid,
                             package: pkg,
                             commitDate: .init(timeIntervalSince1970: 2),
                             reference: .branch("main"))
        let v4 = try Version(id: UUID(),
                             package: pkg,
                             commitDate: nil,
                             reference: .branch("main"))
        let v5 = try Version(id: UUID(), package: pkg, reference: .tag(1, 2, 3))
        let v6 = try Version(id: UUID(), package: pkg, reference: nil)

        // MUT
        let latest = [v1, v2, v3, v4, v5, v6].shuffled().latestBranchVersion

        // validate
        XCTAssertEqual(latest?.id, vid)
    }

}
