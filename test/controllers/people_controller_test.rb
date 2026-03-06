require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    person = Person.create!(name: "テスト太郎")

    get person_url(person)
    assert_response :success
  end
end