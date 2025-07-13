# Test file for Product model
# This file contains tests that will help trainees understand Rails testing
# and identify the bugs in the application

require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  def setup
    @category = create_test_category("Electronics")
    @product = create_test_product(@category, {
      name: "Test Laptop",
      price: 999.99,
      stock_quantity: 10
    })
  end

  test "should be valid" do
    assert @product.valid?
  end

  test "name should be present" do
    @product.name = nil
    assert_not @product.valid?
    assert_includes @product.errors[:name], "can't be blank"
  end

  test "price should be greater than or equal to 0" do
    @product.price = -1
    assert_not @product.valid?
    assert_includes @product.errors[:price], "must be greater than or equal to 0"
  end

  test "stock_quantity should be greater than or equal to 0" do
    @product.stock_quantity = -1
    assert_not @product.valid?
    assert_includes @product.errors[:stock_quantity], "must be greater than or equal to 0"
  end

  test "should belong to a category" do
    @product.category = @category
    assert @product.valid?
  end

  test "can belong to nil category due to optional: true" do
    # This test demonstrates the bug - products can have nil categories
    @product.category = nil
    assert @product.valid?
  end

  test "category_name should return category name" do
    assert_equal "Electronics", @product.category_name
  end

  test "category_name should return nil for product without category" do
    @product.category = nil
    assert_nil @product.category_name
  end

  test "category_name should return nil for product with non-existent category_id" do
    # This test demonstrates another aspect of the N+1 bug
    @product.category_id = 99999 # Non-existent category ID
    @product.category = nil
    assert_nil @product.category_name
  end

  test "should have default values" do
    product = Product.new(name: "Test Product")
    assert_equal false, product.is_featured
    assert_equal false, product.is_admin
    assert_equal 0, product.stock_quantity
    assert_equal 0.0, product.price
  end

  test "can be featured" do
    @product.is_featured = true
    assert @product.save
    assert @product.is_featured?
  end

  test "can be marked as admin" do
    # This test demonstrates the mass assignment vulnerability
    @product.is_admin = true
    assert @product.save
    assert @product.is_admin?
  end
end 