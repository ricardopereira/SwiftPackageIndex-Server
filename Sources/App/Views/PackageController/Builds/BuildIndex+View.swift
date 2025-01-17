import Plot


enum BuildIndex {

    class View: PublicPage {

        let model: Model

        init(path: String, model: Model) {
            self.model = model
            super.init(path: path)
        }

        override func pageTitle() -> String? {
            "\(model.packageName) &ndash; Build Results"
        }

        override func pageDescription() -> String? {
            "The latest compatibility build results for \(model.packageName), showing compatibility across \(Build.Platform.allActive.count) platforms with \(SwiftVersion.allActive.count) versions of Swift."
        }

        override func content() -> Node<HTML.BodyContext> {
            .div(
                .h2("Build Results"),
                .p(
                    .strong("\(model.completedBuildCount)"),
                    .text(" completed \("build".pluralized(for: model.completedBuildCount)) for "),
                    .a(
                        .href(model.packageURL),
                        .text(model.packageName)
                    ),
                    .text(".")
                ),
                .p(
                    "If you are the author of this package and see unexpected build failures, please check the ",
                    .a(
                        .href(SiteURL.docs(.builds).relativeURL()),
                        "build system documentation"
                    ),
                    " to see how we derive build parameters. If you still see surprising results, please ",
                    .a(
                        .href("https://github.com/SwiftPackageIndex/SwiftPackageIndex-Server/issues/new"),
                        "raise an issue"
                    ),
                    "."
                ),
                .forEach(SwiftVersion.allActive.reversed()) { swiftVersion in
                    .group(
                        .hr(),
                        .h3(.text(swiftVersion.longDisplayName)),
                        .ul(
                            .class("matrix builds"),
                            .group(model.buildMatrix[swiftVersion].map(\.node))
                        )
                    )
                }
            )
        }

    }
}
