require "test_helper"

class Stock::RegisterTest < ActiveSupport::TestCase
  test "creates drug item and lot for manual stock registration" do
    person = Person.create!(name: "太郎")

    assert_difference -> { DrugProduct.count }, +1 do
      assert_difference -> { MedicationItem.count }, +1 do
        assert_difference -> { MedicationLot.count }, +1 do
          result = Stock::Register.call(
            person: person,
            drug_name: "ロキソニン錠60mg",
            base_date: Date.current,
            expires_on: Date.current + 365,
            quantity: 10
          )

          drug = result[:drug]
          item = result[:item]
          lot  = result[:lot]

          assert_equal "ロキソニン錠60mg", drug.display_name
          assert_equal person, item.person
          assert_equal drug, item.drug_product

          assert_equal 10, lot.quantity_initial
          assert_equal 10, lot.quantity_remaining
          assert_equal Date.current, lot.base_date
          assert_equal Date.current + 365, lot.expires_on
        end
      end
    end
  end

  test "reuses existing drug product and medication item" do
    person = Person.create!(name: "花子")
    drug = DrugProduct.create!(display_name: "カロナール")
    item = MedicationItem.create!(person: person, drug_product: drug, active: true)

    assert_no_difference -> { DrugProduct.count } do
      assert_no_difference -> { MedicationItem.count } do
        assert_difference -> { MedicationLot.count }, +1 do
          result = Stock::Register.call(
            person: person,
            drug_product: drug,
            base_date: Date.current,
            expires_on: Date.current + 30,
            quantity: 5
          )

          assert_equal drug, result[:drug]
          assert_equal item, result[:item]
          assert_equal 5, result[:lot].quantity_initial
          assert_equal 5, result[:lot].quantity_remaining
        end
      end
    end
  end

  test "raises when quantity is invalid" do
    person = Person.create!(name: "次郎")

    error = assert_raises(ArgumentError) do
      Stock::Register.call(
        person: person,
        drug_name: "ムコダイン",
        base_date: Date.current,
        expires_on: Date.current + 14,
        quantity: 0
      )
    end

    assert_match "数量は1以上", error.message
  end
end