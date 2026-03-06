require "test_helper"

class Imports::RegisterAndSeedStockTest < ActiveSupport::TestCase
  test "registers import and creates stock lots from tc08 qr" do
    person = Person.create!(name: "太郎")

    raw_text = <<~TEXT
      JAHISTC08,1,2
      5,20260306
      201,1,ロキソニン錠60mg,1,錠,2,1234567890
      201,2,カロナール錠200,2,錠,2,9999999999
    TEXT

    import = Import.create!(raw_text: raw_text, source: "qr")

    assert_difference -> { DrugProduct.count }, +2 do
      assert_difference -> { MedicationItem.count }, +2 do
        assert_difference -> { MedicationLot.count }, +2 do
          Imports::RegisterAndSeedStock.new(
            import: import,
            person: person,
            quantity: 3
          ).call!
        end
      end
    end

    import.reload
    assert_equal person, import.person

    item1 = MedicationItem.joins(:drug_product)
                          .find_by!(person: person, drug_products: { display_name: "ロキソニン錠60mg" })
    item2 = MedicationItem.joins(:drug_product)
                          .find_by!(person: person, drug_products: { display_name: "カロナール錠200" })

    lot1 = item1.medication_lots.first
    lot2 = item2.medication_lots.first

    assert_equal Date.new(2026, 3, 6), lot1.base_date
    assert_equal 3, lot1.quantity_initial
    assert_equal 3, lot1.quantity_remaining

    assert_equal Date.new(2026, 3, 6), lot2.base_date
    assert_equal 3, lot2.quantity_initial
    assert_equal 3, lot2.quantity_remaining
  end

  test "uses per-drug quantities when quantities are given" do
    person = Person.create!(name: "花子")

    raw_text = <<~TEXT
      JAHISTC08,1,2
      5,20260306
      201,1,ロキソニン錠60mg,1,錠,2,1234567890
      201,2,カロナール錠200,2,錠,2,9999999999
    TEXT

    import = Import.create!(raw_text: raw_text, source: "qr")

    Imports::RegisterAndSeedStock.new(
      import: import,
      person: person,
      quantity: 1,
      quantities: { "0" => "10", "1" => "5" }
    ).call!

    item1 = MedicationItem.joins(:drug_product)
                          .find_by!(person: person, drug_products: { display_name: "ロキソニン錠60mg" })
    item2 = MedicationItem.joins(:drug_product)
                          .find_by!(person: person, drug_products: { display_name: "カロナール錠200" })

    assert_equal 10, item1.medication_lots.first.quantity_initial
    assert_equal 10, item1.medication_lots.first.quantity_remaining

    assert_equal 5, item2.medication_lots.first.quantity_initial
    assert_equal 5, item2.medication_lots.first.quantity_remaining
  end

  test "raises when qr is not jahis tc08" do
    person = Person.create!(name: "次郎")
    import = Import.create!(raw_text: "NOT_TC08", source: "qr")

    error = assert_raises(ArgumentError) do
      Imports::RegisterAndSeedStock.new(
        import: import,
        person: person,
        quantity: 3
      ).call!
    end

    assert_match "JAHISTC08形式ではありません", error.message
    assert_nil import.reload.person_id
  end

  test "raises when import is already registered" do
    person1 = Person.create!(name: "太郎")
    person2 = Person.create!(name: "花子")

    raw_text = <<~TEXT
      JAHISTC08,1,2
      5,20260306
      201,1,ロキソニン錠60mg,1,錠,2,1234567890
    TEXT

    import = Import.create!(raw_text: raw_text, source: "qr", person: person1)

    error = assert_raises(ArgumentError) do
      Imports::RegisterAndSeedStock.new(
        import: import,
        person: person2,
        quantity: 3
      ).call!
    end

    assert_match "このQRはすでに登録されています", error.message
    assert_equal person1, import.reload.person
  end
end