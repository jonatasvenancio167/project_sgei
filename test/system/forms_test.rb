require "application_system_test_case"

class FormsTest < ApplicationSystemTestCase
  setup do
    @form = forms(:one)
  end

  test "visiting the index" do
    visit forms_url
    assert_selector "h1", text: "Forms"
  end

  test "should create form" do
    visit forms_url
    click_on "New form"

    click_on "Create Form"

    assert_text "Form was successfully created"
    click_on "Back"
  end

  test "should update Form" do
    visit form_url(@form)
    click_on "Edit this form", match: :first

    click_on "Update Form"

    assert_text "Form was successfully updated"
    click_on "Back"
  end

  test "should destroy Form" do
    visit form_url(@form)
    click_on "Destroy this form", match: :first

    assert_text "Form was successfully destroyed"
  end
end
