# periodic-download

CRONなどで設定し、定期的にダウンロードするためのプログラムです。

### 使用方法

#### 初回セットアップ

本プログラムはHTTPレスポンスヘッダをJSON形式に変換するために、HTTP Header Converterを利用します。
ビルド後、リンクが張られることでダウンロードが実行可能になります。

```bash
cd bin
chmod +x setup.sh
./setup.sh --converter ./header
```

#### コマンド実行例

コマンドで実行する場合はconv/main/header.goを使用します。
パイプで繋げれば、標準出力を入力データにすることが可能です。

```bash
./download.sh --url https://example.com --converter ./header --last-modified ./last_modified.dat
```

1. 1回目はダウンロードが行われ、コンソール上には"Download completed."が出力されます。
2. 2回目以降は事前に更新確認を行います。更新がない場合、コンソール上には"Content is not updated."が出力されます。

尚、戻り値はいずれも0（正常終了）が返されます。
