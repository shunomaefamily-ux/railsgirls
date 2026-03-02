# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# db/seeds.rb
# frozen_string_literal: true

return unless Rails.env.development?

ActiveRecord::Base.transaction do
  puts "== seeding (development) =="

  # まっさらに作り直したい場合はコメント外す（開発専用）
  IntakeLog.delete_all if defined?(IntakeLog)
  MedicationLot.delete_all
  MedicationItem.delete_all
  DrugProduct.delete_all
  Person.delete_all

  # --- People ---
  taro   = Person.find_or_create_by!(name: "太郎")
  hanako = Person.find_or_create_by!(name: "花子")

  # --- DrugProducts ---
  loxonin = DrugProduct.find_or_create_by!(
    display_name: "ロキソニンS",
    default_shelf_life_days: 365
  )
  mucosta = DrugProduct.find_or_create_by!(
    display_name: "ムコスタ錠100mg",
    default_shelf_life_days: 730
  )

  # --- MedicationItems (棚) ---
  taro_lox = MedicationItem.find_or_create_by!(person: taro, drug_product: loxonin) do |item|
    item.active = true if item.respond_to?(:active=)
  end
  taro_lox.update!(active: true) if taro_lox.respond_to?(:active) && taro_lox.active != true

  taro_muc = MedicationItem.find_or_create_by!(person: taro, drug_product: mucosta) do |item|
    item.active = true if item.respond_to?(:active=)
  end
  taro_muc.update!(active: true) if taro_muc.respond_to?(:active) && taro_muc.active != true

  hana_lox = MedicationItem.find_or_create_by!(person: hanako, drug_product: loxonin) do |item|
    item.active = true if item.respond_to?(:active=)
  end
  hana_lox.update!(active: true) if hana_lox.respond_to?(:active) && hana_lox.active != true

  # --- MedicationLots (ロット) ---
  # 太郎 x ロキソニン：期限切れ / 期限近い / 余裕あり（3ロット）→ 期限表示とFIFO確認ができる
  MedicationLot.create!(
    medication_item: taro_lox,
    base_date: Date.current - 60,
    expires_on: Date.current - 1,      # 期限切れ（赤）
    quantity_remaining: 4
  )
  MedicationLot.create!(
    medication_item: taro_lox,
    base_date: Date.current - 14,
    expires_on: Date.current + 7,      # 期限近い（オレンジ想定）
    quantity_remaining: 8
  )
  MedicationLot.create!(
    medication_item: taro_lox,
    base_date: Date.current - 3,
    expires_on: Date.current + 200,    # 余裕あり
    quantity_remaining: 12
  )

  # 太郎 x ムコスタ：余裕あり（1ロット）
  MedicationLot.create!(
    medication_item: taro_muc,
    base_date: Date.current - 20,
    expires_on: Date.current + 300,
    quantity_remaining: 20
  )

  # 花子 x ロキソニン：在庫ゼロ（0ロット or quantity_remaining=0 のロット）
  # 「表示は出るが +1消費はdisabled」を確認できる
  MedicationLot.create!(
    medication_item: hana_lox,
    base_date: Date.current - 10,
    expires_on: Date.current + 100,
    quantity_remaining: 0
  )

  # --- IntakeLogs（任意：最終服用の表示確認をしたい場合だけ）---
  if defined?(IntakeLog)
    IntakeLog.create!(medication_item: taro_lox, quantity_taken: 1, taken_at: 2.days.ago)
    IntakeLog.create!(medication_item: taro_lox, quantity_taken: 1, taken_at: 1.day.ago)
  end

  puts "seeded people: #{Person.count}"
  puts "seeded items:  #{MedicationItem.count}"
  puts "seeded lots:   #{MedicationLot.count}"
end