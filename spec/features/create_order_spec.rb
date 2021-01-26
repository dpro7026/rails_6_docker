require "rails_helper"

RSpec.feature "Creating Order" do
  scenario "A user creates a new order" do
    visit "/"

    click_link "New Order"
    fill_in "Product", with: "Cheeseburger"
    click_button "Purchase Now"

    expect(page).to have_content("Order Confirmed")
    expect(page.current_path).to eq(order_confirm_path)
  end
end