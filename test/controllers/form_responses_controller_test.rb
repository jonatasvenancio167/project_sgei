require "test_helper"

class FormResponsesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @form_response = form_responses(:one)
  end

  test "should get index" do
    get form_responses_url
    assert_response :success
  end

  test "should get new" do
    get new_form_response_url
    assert_response :success
  end

  test "should create form_response" do
    assert_difference("FormResponse.count") do
      post form_responses_url, params: { form_response: { form_id: @form_response.form_id, submitted_at: @form_response.submitted_at, user_id: @form_response.user_id } }
    end

    assert_redirected_to form_response_url(FormResponse.last)
  end

  test "should show form_response" do
    get form_response_url(@form_response)
    assert_response :success
  end

  test "should get edit" do
    get edit_form_response_url(@form_response)
    assert_response :success
  end

  test "should update form_response" do
    patch form_response_url(@form_response), params: { form_response: { form_id: @form_response.form_id, submitted_at: @form_response.submitted_at, user_id: @form_response.user_id } }
    assert_redirected_to form_response_url(@form_response)
  end

  test "should destroy form_response" do
    assert_difference("FormResponse.count", -1) do
      delete form_response_url(@form_response)
    end

    assert_redirected_to form_responses_url
  end
end
