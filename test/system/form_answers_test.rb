require "application_system_test_case"

class FormAnswersTest < ApplicationSystemTestCase
  setup do
    @form_answer = form_answers(:one)
  end

  test "visiting the index" do
    visit form_answers_url
    assert_selector "h1", text: "Form answers"
  end

  test "should create form answer" do
    visit form_answers_url
    click_on "New form answer"

    click_on "Create Form answer"

    assert_text "Form answer was successfully created"
    click_on "Back"
  end

  test "should update Form answer" do
    visit form_answer_url(@form_answer)
    click_on "Edit this form answer", match: :first

    click_on "Update Form answer"

    assert_text "Form answer was successfully updated"
    click_on "Back"
  end

  test "should destroy Form answer" do
    visit form_answer_url(@form_answer)
    click_on "Destroy this form answer", match: :first

    assert_text "Form answer was successfully destroyed"
  end
end
