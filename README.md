# 家庭用おくすり管理アプリ

家庭内で使用する薬の **在庫管理・服薬記録** を行うアプリです。

薬を **人ごとに管理**し、**QRコードから薬情報を取り込み**、  
**ロット単位で在庫管理し FIFO で消費**できるように設計しています。

Androidアプリをフロントエンドとして、  
Ruby on Rails API と連携する構成になっています。

---

# デモ

（デモ環境URLができたら追加）
### Rails API サーバー（Render）

https://railsgirls-psq6.onrender.com/

※ Renderの無料プランのため、初回アクセス時は起動に30秒ほどかかる場合があります。


### Android

https://github.com/shunomaefamily-ux/okusuriyouapuri

### Rails

https://github.com/shunomaefamily-ux/railsgirls

---

# システム構成


Android App (Kotlin / Jetpack Compose)
│
│ HTTP (Retrofit)
▼
Rails API (Ruby on Rails)
│
▼
Database
開発 : SQLite3
本番 : PostgreSQL (Render)


---

# 使用技術

## Backend

- Ruby 3.x
- Ruby on Rails
- SQLite3（開発）
- PostgreSQL（本番）
- Render（デプロイ予定）

### テスト

- Minitest

---

## Android

- Kotlin
- Jetpack Compose
- Retrofit

---

# 主な機能

## 薬マスタ管理

薬の基本情報を管理します。

- 薬名
- 規格
- メーカー

---

## 人ごとの薬管理

家庭内の人ごとに薬を管理します。

例

- 父
- 母
- 子供

---

## 薬在庫管理（ロット単位）

薬を **ロット単位で管理**します。

管理項目

- ロット
- 使用期限
- 数量

---

## FIFO在庫消費

服薬記録登録時に **古いロットから自動で在庫を消費**します。


Stock::Consume


サービスオブジェクトとして実装しています。

---

## 服薬ログ

誰がいつ薬を飲んだかを記録します。


IntakeLog


---

## QRコードから薬情報取り込み

JAHIS規格のQRコードを読み取り、  
薬情報を自動登録します。


Imports::JahisExtractor


---

# モデル構成

主要モデル


Person
DrugProduct
MedicationItem
MedicationLot
IntakeLog
Import


---

# モデル設計

## DrugProduct

薬のマスタ情報

例

- 薬名
- 規格

---

## MedicationItem

人ごとの薬管理


Person
└ MedicationItem
└ MedicationLot


---

## MedicationLot

ロット単位の在庫管理

管理内容

- 数量
- 使用期限

---

## IntakeLog

服薬履歴

---

## Import

QRコード取込履歴

---

# 設計上の工夫

## 薬マスタと利用薬を分離


DrugProduct
MedicationItem


を分離することで

- 薬マスタの再利用
- 人ごとの管理

を実現しています。

---

## ロット単位在庫管理


MedicationLot


により

- 使用期限
- 在庫管理

を行います。

---

## FIFO消費

古いロットから消費するように


Stock::Consume


サービスオブジェクトで実装しています。

---

## QRコード取り込み

JAHIS規格QRから薬情報を解析する


Imports::JahisExtractor


を実装しています。

---

# セットアップ

## Rails

```bash
git clone https://github.com/shunomaefamily-ux/railsgirls.git
cd railsgirls
bundle install
rails db:create
rails db:migrate
rails s
Android
git clone https://github.com/shunomaefamily-ux/okusuriyouapuri.git

Android Studioで開きます。

セキュリティ

機密情報は

credentials.yml.enc

で管理しています。

config/master.key

は .gitignore により
GitHubには含まれません。

今後の改善

テスト拡充

UI改善

通知機能

在庫アラート

家族共有機能

作成背景

家庭内で薬の管理が分散し、

在庫がわからない

使用期限がわからない

服薬履歴が残らない

という課題を解決するために作成しました。


---

### ① ER図


Person
└ MedicationItem
└ MedicationLot
└ IntakeLog
DrugProduct
Import


### ② アプリ画面スクショ


/docs/images
