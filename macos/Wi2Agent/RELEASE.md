Appleシリコン搭載Mac・macOS 14以降向けのインストーラーです。

1. `Wi2Agent-macos-arm64.pkg`をダウンロードします。
2. ターミナルで次を実行します。保存先を変更した場合はパスも変更してください。

   ```bash
   xattr -d com.apple.quarantine ~/Downloads/Wi2Agent-macos-arm64.pkg
   ```

3. `.pkg`をダブルクリックし、画面に従ってインストールします。
4. `/Applications/Wi2Agent.app`を開き、API接続先とトークンを設定します。

起動中のWi2Agentは、インストール前にメニューバーから終了してください。アプリはad-hoc署名、インストーラーは未署名・未公証です。
