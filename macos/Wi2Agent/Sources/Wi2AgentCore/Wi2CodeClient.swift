import Foundation

public enum Wi2CodeClientError: Error, LocalizedError {
  case invalidEndpoint
  case invalidResponse
  case invalidCode
  case status(Int)

  public var errorDescription: String? {
    switch self {
    case .invalidEndpoint: "API接続先を設定してください。"
    case .invalidResponse: "コードAPIの応答を取得できませんでした。"
    case .invalidCode: "コードAPIが8文字英数字以外を返しました。"
    case let .status(status): "コードAPIがHTTP \(status)を返しました。"
    }
  }
}

public struct Wi2CodeClient {
  private let session: URLSession

  public init(session: URLSession = .shared) {
    self.session = session
  }

  public func fetchCode(endpoint: URL, token: String) async throws -> String {
    var request = URLRequest(url: endpoint)
    request.timeoutInterval = 75
    request.cachePolicy = .reloadIgnoringLocalCacheData
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = Data("{}".utf8)

    let (data, response) = try await session.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw Wi2CodeClientError.invalidResponse
    }
    guard httpResponse.statusCode == 200 else {
      throw Wi2CodeClientError.status(httpResponse.statusCode)
    }

    let code = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    guard code.range(of: "^[A-Za-z0-9]{8}$", options: .regularExpression) != nil else {
      throw Wi2CodeClientError.invalidCode
    }
    return code
  }
}
