require "application_system_test_case"

class UserNotificationsTest < ApplicationSystemTestCase
  setup do
    @user_notification = user_notifications(:one)
  end

  test "visiting the index" do
    visit user_notifications_url
    assert_selector "h1", text: "User notifications"
  end

  test "should create user notification" do
    visit user_notifications_url
    click_on "New user notification"

    click_on "Create User notification"

    assert_text "User notification was successfully created"
    click_on "Back"
  end

  test "should update User notification" do
    visit user_notification_url(@user_notification)
    click_on "Edit this user notification", match: :first

    click_on "Update User notification"

    assert_text "User notification was successfully updated"
    click_on "Back"
  end

  test "should destroy User notification" do
    visit user_notification_url(@user_notification)
    click_on "Destroy this user notification", match: :first

    assert_text "User notification was successfully destroyed"
  end
end
