import SwiftUI

struct APISettingsView: View {
  @ObservedObject var viewModel: Wi2SessionViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("API設定").font(.title2.bold())
      Form {
        TextField("API接続先", text: $viewModel.apiEndpoint, prompt: Text("https://example.com/code"))
        SecureField("APIトークン", text: $viewModel.apiToken)
      }
      .textFieldStyle(.roundedBorder)
      if viewModel.isError {
        Text(viewModel.status).foregroundStyle(.red)
          .fixedSize(horizontal: false, vertical: true)
      }
      HStack {
        Button("キャンセル") { dismiss() }
          .keyboardShortcut(.cancelAction)
        Spacer()
        Button("Keychainへ保存") {
          viewModel.saveToken()
          if !viewModel.isError { dismiss() }
        }
        .keyboardShortcut(.defaultAction)
        .disabled(viewModel.apiEndpoint.isEmpty || viewModel.apiToken.isEmpty || viewModel.isBusy)
      }
    }
    .padding(24)
    .frame(width: 440)
  }
}
