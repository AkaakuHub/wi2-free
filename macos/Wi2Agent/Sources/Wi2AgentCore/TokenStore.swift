import Foundation
import Security

public enum TokenStoreError: Error, LocalizedError {
  case apiTokenUnavailable
  case keychainFailure

  public var errorDescription: String? {
    switch self {
    case .apiTokenUnavailable: "APIトークンがKeychainに登録されていません。アプリの設定から保存してください。"
    case .keychainFailure: "Keychainへのアクセスに失敗しました。"
    }
  }
}

public enum TokenStore {
  private static let account = "api-token"
  private static let service = "app.wi2-agent"

  public static func load() throws -> String {
    try load(account: account, unavailableError: .apiTokenUnavailable)
  }

  public static func hasToken() -> Bool {
    (try? load()) != nil
  }

  public static func save(_ token: String) throws {
    try save(token, account: account)
  }

  private static func load(account: String, unavailableError: TokenStoreError) throws -> String {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: account,
      kSecAttrService as String: service,
      kSecReturnData as String: true,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess, let data = item as? Data, let token = String(data: data, encoding: .utf8) else {
      throw status == errSecItemNotFound ? unavailableError : TokenStoreError.keychainFailure
    }
    return token
  }

  private static func save(_ value: String, account: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: account,
      kSecAttrService as String: service,
    ]
    let attributes = [kSecValueData as String: Data(value.utf8)]
    let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if updateStatus == errSecItemNotFound {
      var item = query
      item[kSecValueData as String] = Data(value.utf8)
      guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else {
        throw TokenStoreError.keychainFailure
      }
      return
    }
    guard updateStatus == errSecSuccess else {
      throw TokenStoreError.keychainFailure
    }
  }
}
