# Test file for ProductsController
# This file contains tests that will help trainees understand Rails controller testing
# and identify the bugs in the application

require 'test_helper'

class Api::V1::ProductsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @category = create_test_category("Electronics")
    @product = create_test_product(@category, {
      name: "Test Laptop",
      price: 999.99,
      stock_quantity: 10
    })
  end

  test "should get index" do
    api_get "/api/v1/products"
    assert_json_response
    assert_not_nil json_response
  end

  test "should get show" do
    api_get "/api/v1/products/#{@product.id}"
    assert_json_response
    assert_equal @product.name, json_response["name"]
  end

  test "should create product" do
    assert_difference('Product.count') do
      api_post "/api/v1/products", {
        product: {
          name: "New Product",
          description: "New Description",
          price: 50.00,
          stock_quantity: 5,
          category_id: @category.id
        }
      }
    end
    assert_json_response(:created)
  end

  test "should not create product with invalid data" do
    assert_no_difference('Product.count') do
      api_post "/api/v1/products", {
        product: {
          name: nil,
          price: -1
        }
      }
    end
    assert_json_response(:unprocessable_entity)
  end

  test "should update product" do
    api_patch "/api/v1/products/#{@product.id}", {
      product: {
        name: "Updated Product",
        price: 1500.00
      }
    }
    assert_json_response
    @product.reload
    assert_equal "Updated Product", @product.name
    assert_equal 1500.00, @product.price
  end

  test "should delete product" do
    assert_difference('Product.count', -1) do
      api_delete "/api/v1/products/#{@product.id}"
    end
    assert_response :no_content
  end

  test "should feature product" do
    api_patch "/api/v1/products/#{@product.id}/feature"
    assert_json_response
    @product.reload
    assert @product.is_featured?
  end

  # Tests for the bugs

  test "should expose is_admin field in index response" do
    # This test demonstrates the mass assignment vulnerability
    @product.update!(is_admin: true)
    api_get "/api/v1/products"
    assert_json_response
    product_response = json_response.find { |p| p["id"] == @product.id }
    assert product_response["is_admin"]
  end

  test "should allow mass assignment of is_admin through create" do
    # This test demonstrates the mass assignment vulnerability
    api_post "/api/v1/products", {
      product: {
        name: "Admin Product",
        description: "Admin Description",
        price: 100.00,
        stock_quantity: 1,
        category_id: @category.id,
        is_admin: true  # This should not be allowed
      }
    }
    assert_json_response(:created)
    product = Product.last
    assert product.is_admin?  # This demonstrates the bug
  end

  test "should allow mass assignment of is_admin through update" do
    # This test demonstrates the mass assignment vulnerability
    api_patch "/api/v1/products/#{@product.id}", {
      product: {
        name: "Updated Admin Product",
        is_admin: true  # This should not be allowed
      }
    }
    assert_json_response
    @product.reload
    assert @product.is_admin?  # This demonstrates the bug
  end

  test "should handle products with nil categories" do
    # This test demonstrates the N+1 query and nil category bugs
    product_without_category = create_test_product(nil, {
      name: "Product Without Category",
      category_id: nil
    })
    
    api_get "/api/v1/products"
    assert_json_response
    
    product_response = json_response.find { |p| p["id"] == product_without_category.id }
    assert_nil product_response["category_name"]
  end

  test "should handle products with non-existent category_id" do
    # This test demonstrates another aspect of the N+1 bug
    product_with_bad_category = create_test_product(nil, {
      name: "Product With Bad Category",
      category_id: 99999  # Non-existent category
    })
    
    api_get "/api/v1/products"
    assert_json_response
    
    product_response = json_response.find { |p| p["id"] == product_with_bad_category.id }
    assert_nil product_response["category_name"]
  end
end 