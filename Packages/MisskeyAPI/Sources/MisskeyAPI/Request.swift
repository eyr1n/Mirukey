import APIKit
import Foundation

public extension MisskeyAPI {
  protocol Request: APIKit.Request {}
}

public extension MisskeyAPI.Request {
  var baseURL: URL { URL(string: "https://misskey.invalid")! }
}

public extension MisskeyAPI.Request where Self: Encodable {
  var bodyParameters: BodyParameters? {
    EncodableBodyParameters(value: self)
  }
}

public extension MisskeyAPI.Request where Response: Decodable {
  var dataParser: DataParser { DecodableDataParser() }
  func response(from object: Any, urlResponse: HTTPURLResponse) throws
    -> Response
  {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(Response.self, from: object as! Data)
  }
}

private struct EncodableBodyParameters: BodyParameters {
  let value: any Encodable
  var contentType: String { "application/json" }
  func buildEntity() throws -> RequestBodyEntity {
    return .data(try JSONEncoder().encode(value))
  }
}

private struct DecodableDataParser: DataParser {
  var contentType: String? { "application/json" }
  func parse(data: Data) throws -> Any { data }
}
