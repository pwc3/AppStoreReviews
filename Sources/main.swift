import Foundation
import MiniDOM

struct Review {
    var element: Element

    init(element: Element) {
        self.element = element
    }

    var id: String? {
        element.childElements(withName: "id").first?.textValue
    }

    var title: String? {
        element.childElements(withName: "title").first?.textValue
    }

    var content: String? {
        element.childElements(withName: "content")
            .first {
                $0.attributes?["type"] == "text"
            }?
            .textValue?
            .replacingOccurrences(of: "\n", with: " ")
    }

    var rating: String? {
        element.childElements(withName: "im:rating").first?.textValue
    }

    var version: String? {
        element.childElements(withName: "im:version").first?.textValue
    }

    var updated: String? {
        element.childElements(withName: "updated").first?.textValue
    }

    static var headerRow: [String] {
        ["id", "title", "content", "rating", "version", "updated"]
    }

    var row: [String] {
        [id ?? "", title ?? "", content ?? "", rating ?? "", version ?? "", updated ?? ""]
    }
}

func document(for url: URL) throws -> Document {
    let parser = Parser(contentsOf: url)!
    return try parser.parse().get()
}

func reviews(at url: URL) throws -> [Review] {
    let document = try document(for: url)
    return document.elements(withTagName: "entry").map {
        Review(element: $0)
    }
}

func reviews(forID id: String, page: Int) throws -> [Review] {
    let url = URL(string: "https://itunes.apple.com/us/rss/customerreviews/page=\(page)/id=\(id)/xml")!
    return try reviews(at: url)
}

func reviews(forID id: String) throws -> [Review] {
    try (1...10).flatMap { page in
        try reviews(forID: id, page: page)
    }
}

func tsv(for reviews: [Review]) -> String {
    let header = [Review.headerRow.joined(separator: "\t")]
    let lines = reviews.map {
        $0.row.joined(separator: "\t")
    }
    return (header + lines).joined(separator: "\n")
}

func main(args: [String]) throws -> Int32 {
    let ids = args[1...]
    for id in ids {
        let reviews = try reviews(forID: id)
        print("Read \(reviews.count) reviews for \(id)")

        let tsv = tsv(for: reviews)
        try tsv.write(toFile: "\(id).txt", atomically: true, encoding: .utf8)
        print("Wrote to \(id).txt")
    }
    return 0
}

do {
    exit(try main(args: CommandLine.arguments))
}
catch {
    print("Error: \(error)")
    exit(1)
}
