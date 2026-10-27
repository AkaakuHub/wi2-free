# wi2-free

iPhoneショートカットまたはmacOSの`curl`から`POST /code`を1回呼び出し、Wi2のゲストコードを同じHTTPレスポンスで返すCloudflare Workerです。

メール送信と返信受信には、利用者が用意したGoogle Apps ScriptとGmailを使用します。

以下の`example.com`は、自分で設定したWorkerのドメインに置き換えてください。

```text
https://example.com
```

## API

### `POST /code`

認証ヘッダーが必要です。本文を省略すると、`wrangler.jsonc`の`DEFAULT_WI2_TO`を使用します。

```bash
curl --fail-with-body --max-time 70 \
  -X POST \
  -H "Authorization: Bearer $WI2_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}' \
  https://example.com/code
```

店舗固有の送信先を指定する場合は、`@forguest.wi2.ne.jp`のアドレスだけを受け付けます。

```bash
curl --fail-with-body --max-time 70 \
  -X POST \
  -H "Authorization: Bearer $WI2_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"to":"guestsrv-J@forguest.wi2.ne.jp"}' \
  https://example.com/code
```

成功時はプレーンテキストでコードを返します。

```text
AAAy9jxj
```

### `GET /health`

```bash
curl https://example.com/health
```

```json
{"ok":true,"service":"wi2-free"}
```

## 初回設定

### 1. GASの共有秘密鍵

GASの公開Webアプリは外部からPOSTを受けるため、Workerとの通信をHMAC署名で認証します。同じランダム値をGASとCloudflare Workerの両方へ登録します。

1. 次のコマンドでランダム値を生成します。

   ```bash
   openssl rand -hex 32
   ```

2. Apps Scriptプロジェクトの`プロジェクトの設定`から`スクリプト プロパティ`を開き、次を追加します。

   ```text
   名前: WI2_GAS_SHARED_SECRET
   値: 生成したランダム値
   ```

3. 同じ値をCloudflare Worker secretへ登録します。

   ```bash
   pnpm exec wrangler secret put GAS_SHARED_SECRET
   ```

GASの公開URLは`GAS_WEB_APP_URL`というWorker secretへ登録します。

```bash
pnpm exec wrangler secret put GAS_WEB_APP_URL
```

### 2. GASの反映

`.clasp.json.example`を`.clasp.json`へコピーし、自分のスクリプトIDを設定します。GASへソースを反映してから、Apps ScriptでWebアプリとしてデプロイします。

```bash
pnpm push:gas
```

初回はGoogleの権限画面で、メール送信とGmail読み取りを自分のGoogleアカウントで許可します。

### 3. Workerの自動デプロイ

CloudflareでWorkerに独自ドメインを設定し、Git連携を構成すると`main`へのpushでデプロイできます。ドメインやGASのID、個人のメールアドレスはGitへ登録しません。

デプロイ後、`POST /code`を実行します。GASは空の件名・本文でWi2へ送信し、最大60秒間、`cs-info@wi2.co.jp`から届く新着返信だけをGmailの検索インデックスで最大10件取得します。ローカルでメール全件や全フォルダを走査しません。ゲストコードのラベル直後にある8文字英数字を元の大小文字のまま返します。

## 設定値

`wrangler.jsonc`には秘密ではない設定だけを置いています。

- `DEFAULT_WI2_TO`:本文省略時の送信先
- `keep_vars`:Cloudflare上の設定値をデプロイ時に保持します。
- `workers_dev`:`false`。`*.workers.dev`を無効化する設定

`.clasp.json`、`wrangler.local.jsonc`、`.dev.vars`、`.env`とそれらの環境別ファイルはignoreされます。サンプルへ実際の設定値を書き込まないでください。ローカル専用のWorker設定を使う場合は`--config wrangler.local.jsonc`を指定します。

秘密情報はCloudflare Worker secretへ保存します。

- `API_TOKEN`
- `GAS_SHARED_SECRET`
- `GAS_WEB_APP_URL`:GAS Webアプリの`/exec`URL

GAS側の`WI2_GAS_SHARED_SECRET`はApps Scriptのスクリプトプロパティへ保存します。

## iPhoneショートカット

ショートカットアプリで次のアクションを作成します。

1. `URL`へ`https://example.com/code`を設定します。
2. `URLの内容を取得`を追加します。
3. メソッドを`POST`にします。
4. ヘッダーへ次を追加します。
   - `Authorization`:`Bearer <API_TOKEN>`
   - `Content-Type`:`application/json`
5. リクエスト本文をJSONにし、標準の送信先を使う場合は空の辞書にします。
6. 戻り値を`クリップボードにコピー`へ渡します。
7. 戻り値を`結果を表示`または`通知を表示`へ渡します。

店舗固有アドレスを使う場合のJSON本文は次です。

```json
{
  "to": "guestsrv-J@forguest.wi2.ne.jp"
}
```

## macOS用アプリ

GitHubのReleasesからAppleシリコン搭載Mac向けの`Wi2Agent-macos-arm64.pkg`をダウンロードして開くと、インストーラーが`/Applications/Wi2Agent.app`へ配置します。macOS 14以降が必要です。

`v0.3.0`のようなタグのpushでGitHub Actionsがテストとビルドを行い、Releaseへインストーラーを添付します。同じタグの再実行ではSwiftのビルドキャッシュを再利用します。GitHubの制約により、異なるタグ間ではキャッシュを共有できません。アプリはad-hoc署名で、インストーラーは未署名・未公証です。初回起動時の操作は[macOS用README](macos/Wi2Agent/README.md)を参照してください。

`macos/Wi2Agent`はコード取得後にWi2へ接続し、ゲストコードと残り時間を表示するmacOSアプリです。ログイン完了後に次回のコードを取得し、残り2分で通知します。取得失敗時は利用時間内に再試行し、アプリ再起動後も接続情報を復元します。キャプティブポータルへの入力は手動です。手順は[macos/Wi2Agent/README.md](macos/Wi2Agent/README.md)を参照してください。

## セキュリティ

- `/code`はBearer tokenで保護します。
- 送信先は`@forguest.wi2.ne.jp`だけに制限します。
- WorkerからGASへのリクエストはHMAC署名と有効期限で検証します。
- HTTPレスポンスには`Cache-Control: no-store`を設定します。
