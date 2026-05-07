require "application_system_test_case"

class FormResponsesTest < ApplicationSystemTestCase
  setup do
    @form_response = form_responses(:one)
  end

  test "visiting the index" do
    visit form_responses_url
    assert_selector "h1", text: "Form responses"
  end

  test "should create form response" do
    visit form_responses_url
    click_on "New form response"

    fill_in "Form", with: @form_response.form_id
    fill_in "Submitted at", with: @form_response.submitted_at
    fill_in "User", with: @form_response.user_id
    click_on "Create Form response"

    assert_text "Form response was successfully created"
    click_on "Back"
  end

  test "should update Form response" do
    visit form_response_url(@form_response)
    click_on "Edit this form response", match: :first

    fill_in "Form", with: @form_response.form_id
    fill_in "Submitted at", with: @form_response.submitted_at.to_s
    fill_in "User", with: @form_response.user_id
    click_on "Update Form response"

    assert_text "Form response was successfully updated"
    click_on "Back"
  end

  test "should destroy Form response" do
    visit form_response_url(@form_response)
    click_on "Destroy this form response", match: :first

    assert_text "Form response was successfully destroyed"
  end
end
