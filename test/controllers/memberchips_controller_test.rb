require "test_helper"

class MemberchipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @memberchip = memberchips(:one)
  end

  test "should get index" do
    get memberchips_url
    assert_response :success
  end

  test "should get new" do
    get new_memberchip_url
    assert_response :success
  end

  test "should create memberchip" do
    assert_difference("Memberchip.count") do
      post memberchips_url, params: { memberchip: {} }
    end

    assert_redirected_to memberchip_url(Memberchip.last)
  end

  test "should show memberchip" do
    get memberchip_url(@memberchip)
    assert_response :success
  end

  test "should get edit" do
    get edit_memberchip_url(@memberchip)
    assert_response :success
  end

  test "should update memberchip" do
    patch memberchip_url(@memberchip), params: { memberchip: {} }
    assert_redirected_to memberchip_url(@memberchip)
  end

  test "should destroy memberchip" do
    assert_difference("Memberchip.count", -1) do
      delete memberchip_url(@memberchip)
    end

    assert_redirected_to memberchips_url
  end
end
