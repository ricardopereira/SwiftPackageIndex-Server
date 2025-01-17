import Plot
import Vapor


// MARK: - Resource declaration


// The following are all the routes we support and reference from various places, some of them
// static routes (images), others dynamic ones for use in controller definitions.
//
// Introduce nesting by declaring a new type conforming to Resourceable and embed it in the
// parent resource.
//
// Enums based on String are automatically Resourceable via RawRepresentable.


enum Api: Resourceable {
    case packages(_ owner: Parameter<String>, _ repository: Parameter<String>, PackagesPathComponents)
    case packageCollections
    case search
    case version
    case versions(_ id: Parameter<UUID>, VersionsPathComponents)
    
    var path: String {
        switch self {
            case let .packages(.value(owner), .value(repo), next):
                return "packages/\(owner)/\(repo)/\(next.path)"
            case .packages:
                fatalError("path must not be called with a name parameter")
            case .packageCollections:
                return "package-collections"
            case .version:
                return "version"
            case let .versions(.value(id), next):
                return "versions/\(id.uuidString)/\(next.path)"
            case .versions(.key, _):
                fatalError("path must not be called with a name parameter")
            case .search:
                return "search"
        }
    }
    
    var pathComponents: [PathComponent] {
        switch self {
            case let .packages(.key, .key, remainder):
                return ["packages", ":owner", ":repository"] + remainder.pathComponents
            case .packages:
                fatalError("pathComponents must not be called with a value parameter")
            case .packageCollections:
                return ["package-collections"]
            case .search, .version:
                return [.init(stringLiteral: path)]
            case let .versions(.key, remainder):
                return ["versions", ":id"] + remainder.pathComponents
            case .versions(.value, _):
                fatalError("pathComponents must not be called with a value parameter")
        }
    }
    
    enum PackagesPathComponents: String, Resourceable {
        case badge
        case triggerBuilds = "trigger-builds"
    }
    
    enum VersionsPathComponents: String, Resourceable {
        case builds
        case triggerBuild = "trigger-build"
    }
    
}


enum Docs: String, Resourceable {
    case builds
}


enum SiteURL: Resourceable {

    case addAPackage
    case api(Api)
    case author(_ owner: Parameter<String>)
    case builds(_ id: Parameter<UUID>)
    case docs(Docs)
    case faq
    case home
    case images(String)
    case javascripts(String)
    case package(_ owner: Parameter<String>, _ repository: Parameter<String>, PackagePathComponents?)
    case packageCollection(_ owner: Parameter<String>)
    case packageCollections
    case privacy
    case rssPackages
    case rssReleases
    case search
    case siteMap
    case stylesheets(String)
    case tryInPlayground

    var path: String {
        switch self {
            case .addAPackage:
                return "add-a-package"

            case let .api(next):
                return "api/\(next.path)"

            case let .author(.value(owner)):
                return owner

            case .author:
                fatalError("invalid path: \(self)")

            case let .builds(.value(id)):
                return "builds/\(id.uuidString)"

            case .builds(.key):
                fatalError("invalid path: \(self)")

            case let .docs(next):
                return "docs/\(next.path)"

            case .faq:
                return "faq"

            case .home:
                return ""
                
            case let .images(name):
                return "images/\(name)"
                
            case let .javascripts(name):
                return "/\(name).js"

            case let .package(.value(owner), .value(repo), .none):
                let owner = owner.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? owner
                let repo = repo.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? repo
                return "\(owner)/\(repo)"

            case let .package(owner, repo, .some(next)):
                return "\(Self.package(owner, repo, .none).path)/\(next.path)"

            case .package:
                fatalError("invalid path: \(self)")

            case let .packageCollection(.value(owner)):
                return "\(owner)/collection.json"

            case .packageCollection(.key):
                fatalError("invalid path: \(self)")

            case .packageCollections:
                return "package-collections"

            case .privacy:
                return "privacy"

            case .rssPackages:
                return "packages.rss"

            case .rssReleases:
                return "releases.rss"

            case .search:
                return "search"

            case .siteMap:
                return "sitemap.xml"

            case let .stylesheets(name):
                return "/\(name).css"

            case .tryInPlayground:
                return "try-in-a-playground"
        }
    }
    
    var pathComponents: [PathComponent] {
        switch self {
            case .addAPackage, .faq, .home, .packageCollections, .privacy, .rssPackages, .rssReleases,
                 .search, .siteMap, .tryInPlayground:
                return [.init(stringLiteral: path)]
                
            case let .api(next):
                return ["api"] + next.pathComponents
                
            case .author:
                return [":owner"]

            case .builds(.key):
                return ["builds", ":id"]

            case .builds(.value):
                fatalError("pathComponents must not be called with a value parameter")

            case let .docs(next):
                return ["docs"] + next.pathComponents

            case .package(.key, .key, .none):
                return [":owner", ":repository"]
                
            case let .package(k1, k2, .some(next)):
                return Self.package(k1, k2, .none).pathComponents + next.pathComponents

            case .package:
                fatalError("pathComponents must not be called with a value parameter")

            case .packageCollection(.key):
                return [":owner", "collection.json"]

            case .packageCollection(.value):
                fatalError("pathComponents must not be called with a value parameter")

            case .images, .javascripts, .stylesheets:
                fatalError("invalid resource path for routing - only use in static HTML (DSL)")
        }
    }
    
    static let _relativeURL: (String) -> String = { path in
        guard path.hasPrefix("/") else { return "/" + path }
        return path
    }
    
    #if DEBUG
    // make `var` for debug so we can dependency inject
    static var relativeURL = _relativeURL
    #else
    static let relativeURL = _relativeURL
    #endif
    
    static func absoluteURL(_ path: String) -> String {
        Current.siteURL() + relativeURL(path)
    }
    
    static var apiBaseURL: String { absoluteURL("api") }

    enum PackagePathComponents: String, Resourceable {
        case readme
        case builds
        case maintainerInfo = "information-for-package-maintainers"
    }

}


// MARK: - Types for use in resource declaration


protocol Resourceable {
    func absoluteURL(anchor: String?) -> String
    func relativeURL(anchor: String?) -> String
    var path: String { get }
    var pathComponents: [PathComponent] { get }
}


extension Resourceable {
    func absoluteURL(anchor: String? = nil) -> String {
        "\(SiteURL.absoluteURL(path))" + (anchor.map { "#\($0)" } ?? "")
    }
    
    func absoluteURL(parameters: [QueryParameter]) -> String {
        "\(SiteURL.absoluteURL(path))\(parameters.queryString())"
    }
    
    func relativeURL(anchor: String? = nil) -> String {
        "\(SiteURL.relativeURL(path))" + (anchor.map { "#\($0)" } ?? "")
    }

    func relativeURL(parameters: [QueryParameter]) -> String {
        "\(SiteURL.relativeURL(path))\(parameters.queryString())"
    }
}


extension Resourceable where Self: RawRepresentable, RawValue == String {
    var path: String { rawValue }
    var pathComponents: [PathComponent] { [.init(stringLiteral: path)] }
}


enum Parameter<T> {
    case key
    case value(T)
}

struct QueryParameter {
    var key: String
    var value: String

    init(key: String, value: String) {
        self.key = key
        self.value = value
    }

    init(key: String, value: Int) {
        self.init(key: key, value: "\(value)")
    }

    var encodedForQueryString: String {
        let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return "\(encodedKey)=\(encodedValue)"
    }
}
