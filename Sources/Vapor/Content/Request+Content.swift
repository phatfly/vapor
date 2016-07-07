extension HTTPRequest {

    // TODO: Weird but solves problem, keep?
    public typealias ContentDidLoad = (request: HTTPRequest, data: Content) -> Void

    // extensible content loading
    private static var contentDidLoad: ContentDidLoad = { _ in }

    public static func register(_ newLoader: ContentDidLoad) {
        let currentLoader = contentDidLoad
        contentDidLoad = { request, content in
            // FIFO
            currentLoader(request: request, data: content)
            newLoader(request: request, data: content)
        }
    }


    public var data: Content {
        if let data = storage["data"] as? Content {
            return data
        } else {
            let data = Content()
            HTTPRequest.contentDidLoad(request: self, data: data)

            // in closures for weak lazy load, external implementations can use `data.append(self.json)`
            data.append { [weak self] in self?.query }
            data.append { [weak self] in self?.json }
            data.append { [weak self] in self?.formURLEncoded }
            data.append { [weak self] indexes in
                guard let first = indexes.first else { return nil }
                if let string = first as? String {
                    return self?.multipart?[string]
                } else if let int = first as? Int {
                    return self?.multipart?["\(int)"]
                } else {
                    return nil
                }
            }

            storage["data"] = data
            return data
        }
    }
}
