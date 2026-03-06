require "test_helper"

class Stock::ConsumeTest < ActiveSupport::TestCase
  test "consumes lots in FIFO order" do
    person = Person.create!(name: "太郎")
    drug = DrugProduct.create!(display_name: "ロキソニン")
    item = MedicationItem.create!(person: person, drug_product: drug, active: true)

    older_lot = item.medication_lots.create!(
      base_date: Date.current - 10,
      expires_on: Date.current + 100,
      shelf_life_days: 110,
      quantity_initial: 10,
      quantity_remaining: 10
    )

    newer_lot = item.medication_lots.create!(
      base_date: Date.current - 5,
      expires_on: Date.current + 120,
      shelf_life_days: 125,
      quantity_initial: 10,
      quantity_remaining: 10
    )

    assert_difference -> { IntakeLog.count }, +1 do
      Stock::Consume.new(
        medication_item: item,
        quantity: 15,
        taken_at: Time.current
      ).call
    end

    assert_equal 0, older_lot.reload.quantity_remaining
    assert_equal 5, newer_lot.reload.quantity_remaining
  end

  test "rolls back when stock is insufficient" do
    person = Person.create!(name: "花子")
    drug = DrugProduct.create!(display_name: "カロナール")
    item = MedicationItem.create!(person: person, drug_product: drug, active: true)

    lot = item.medication_lots.create!(
      base_date: Date.current - 3,
      expires_on: Date.current + 90,
      shelf_life_days: 93,
      quantity_initial: 3,
      quantity_remaining: 3
    )

    assert_no_difference -> { IntakeLog.count } do
      assert_raises(Stock::Consume::OutOfStock) do
        Stock::Consume.new(
          medication_item: item,
          quantity: 5,
          taken_at: Time.current
        ).call
      end
    end

    assert_equal 3, lot.reload.quantity_remaining
  end

  test "raises when quantity is zero or less" do
    person = Person.create!(name: "次郎")
    drug = DrugProduct.create!(display_name: "ビオフェルミン")
    item = MedicationItem.create!(person: person, drug_product: drug, active: true)

    error = assert_raises(ArgumentError) do
      Stock::Consume.new(
        medication_item: item,
        quantity: 0,
        taken_at: Time.current
      ).call
    end

    assert_match "消費数量は1以上", error.message
  end
end