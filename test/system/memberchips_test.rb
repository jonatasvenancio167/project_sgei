require "application_system_test_case"

class MemberchipsTest < ApplicationSystemTestCase
  setup do
    @memberchip = memberchips(:one)
  end

  test "visiting the index" do
    visit memberchips_url
    assert_selector "h1", text: "Memberchips"
  end

  test "should create memberchip" do
    visit memberchips_url
    click_on "New memberchip"

    click_on "Create Memberchip"

    assert_text "Memberchip was successfully created"
    click_on "Back"
  end

  test "should update Memberchip" do
    visit memberchip_url(@memberchip)
    click_on "Edit this memberchip", match: :first

    click_on "Update Memberchip"

    assert_text "Memberchip was successfully updated"
    click_on "Back"
  end

  test "should destroy Memberchip" do
    visit memberchip_url(@memberchip)
    click_on "Destroy this memberchip", match: :first

    assert_text "Memberchip was successfully destroyed"
  end
end
