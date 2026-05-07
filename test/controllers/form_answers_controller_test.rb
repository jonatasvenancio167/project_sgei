require "test_helper"

class FormAnswersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @form_answer = form_answers(:one)
  end

  test "should get index" do
    get form_answers_url
    assert_response :success
  end

  test "should get new" do
    get new_form_answer_url
    assert_response :success
  end

  test "should create form_answer" do
    assert_difference("FormAnswer.count") do
      post form_answers_url, params: { form_answer: {} }
    end

    assert_redirected_to form_answer_url(FormAnswer.last)
  end

  test "should show form_answer" do
    get form_answer_url(@form_answer)
    assert_response :success
  end

  test "should get edit" do
    get edit_form_answer_url(@form_answer)
    assert_response :success
  end

  test "should update form_answer" do
    patch form_answer_url(@form_answer), params: { form_answer: {} }
    assert_redirected_to form_answer_url(@form_answer)
  end

  test "should destroy form_answer" do
    assert_difference("FormAnswer.count", -1) do
      delete form_answer_url(@form_answer)
    end

    assert_redirected_to form_answers_url
  end
end
