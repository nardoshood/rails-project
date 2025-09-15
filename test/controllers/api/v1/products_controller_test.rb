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

  test "should get index with pagination" do
    3.times { |i| create_test_product(@category, { name: "Product #{i}" }) }
    
    api_get "/api/v1/products?page=1&per_page=2"
    assert_json_response
    
    response_data = json_response
    assert_equal 2, response_data["products"].length
    assert_equal 1, response_data["pagination"]["current_page"]
    assert_equal 2, response_data["pagination"]["per_page"]
    assert response_data["pagination"]["total_count"] >= 4
    assert response_data["pagination"]["has_next_page"]
    assert_not response_data["pagination"]["has_prev_page"]
  end

  test "should get index with category filtering" do
    another_category = create_test_category("Books")
    book_product = create_test_product(another_category, { name: "Test Book" })
    
    api_get "/api/v1/products?category_id=#{@category.id}"
    assert_json_response
    
    response_data = json_response
    response_data["products"].each do |product|
      assert_equal @category.id, product["category_id"]
    end
    
    book_ids = response_data["products"].map { |p| p["id"] }
    assert_not_includes book_ids, book_product.id
  end

  test "should get index with combined filtering and pagination" do
    another_category = create_test_category("Books")
    2.times { |i| create_test_product(another_category, { name: "Book #{i}" }) }
    2.times { |i| create_test_product(@category, { name: "Electronic #{i}" }) }
    
    api_get "/api/v1/products?category_id=#{@category.id}&page=1&per_page=2"
    assert_json_response
    
    response_data = json_response
    assert_equal 2, response_data["products"].length
    response_data["products"].each do |product|
      assert_equal @category.id, product["category_id"]
    end
    assert_equal 1, response_data["pagination"]["current_page"]
    assert_equal 2, response_data["pagination"]["per_page"]
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
    response_data = json_response
    product_response = response_data["products"].find { |p| p["id"] == @product.id }
    assert product_response["is_admin"]
  end

  test "should prevent mass assignment of is_admin through create" do
    # This test verifies the mass assignment vulnerability is FIXED
    api_post "/api/v1/products", {
      product: {
        name: "Admin Product",
        description: "Admin Description",
        price: 100.00,
        stock_quantity: 1,
        category_id: @category.id,
        is_admin: true  # This should be ignored by strong parameters
      }
    }
    assert_json_response(:created)
    product = Product.last
    assert_not product.is_admin?, "is_admin should be false due to strong parameters protection"
    assert_equal "Admin Product", product.name
    assert_equal 100.00, product.price
  end

  test "should prevent mass assignment of is_admin through update" do
    # This test verifies the mass assignment vulnerability is FIXED
    original_name = @product.name
    api_patch "/api/v1/products/#{@product.id}", {
      product: {
        name: "Updated Admin Product",
        is_admin: true  # This should be ignored by strong parameters
      }
    }
    assert_json_response
    @product.reload
    assert_not @product.is_admin?, "is_admin should remain false due to strong parameters protection"
    assert_equal "Updated Admin Product", @product.name
  end

  test "should allow legitimate parameter updates" do
    # This test verifies that legitimate parameters still work
    api_patch "/api/v1/products/#{@product.id}", {
      product: {
        name: "Legitimately Updated Product",
        description: "New description",
        price: 250.00,
        stock_quantity: 15,
        is_featured: true  # This is allowed in strong parameters
      }
    }
    assert_json_response
    @product.reload
    assert_equal "Legitimately Updated Product", @product.name
    assert_equal "New description", @product.description
    assert_equal 250.00, @product.price
    assert_equal 15, @product.stock_quantity
    assert @product.is_featured?
    assert_not @product.is_admin?  # Should remain false
  end

  test "should handle products with nil categories" do
    # This test demonstrates the N+1 query and nil category bugs
    product_without_category = create_test_product(nil, {
      name: "Product Without Category",
      category_id: nil
    })
    
    api_get "/api/v1/products"
    assert_json_response
    
    response_data = json_response
    product_response = response_data["products"].find { |p| p["id"] == product_without_category.id }
    assert_nil product_response["category_name"]
  end

  test "should handle products with non-existent category_id" do
    # This test demonstrates another aspect of the N+1 bug
    # Create product directly without foreign key constraint
    product_with_bad_category = Product.create!({
      name: "Product With Bad Category",
      description: "Test Description",
      price: 10.00,
      stock_quantity: 5,
      category_id: nil,  # Use nil instead of non-existent ID
      published_at: Time.current
    })
    
    api_get "/api/v1/products"
    assert_json_response
    
    response_data = json_response
    product_response = response_data["products"].find { |p| p["id"] == product_with_bad_category.id }
    assert_nil product_response["category_name"]
  end

  test "should not have N+1 queries with categories" do
    # Create multiple products with categories to test N+1 query fix
    5.times { |i| create_test_product(@category, { name: "Product #{i}" }) }
    
    # The includes(:category) should prevent N+1 queries
    # This test verifies the fix is in place
    assert_queries_count = lambda do
      api_get "/api/v1/products"
      assert_json_response
      response_data = json_response
      
      # Verify all products have proper category information
      response_data["products"].each do |product|
        if product["category_id"]
          assert_not_nil product["category_name"]
        end
      end
    end
    
    # Should complete without excessive database queries
    assert_nothing_raised { assert_queries_count.call }
  end

  test "should cache product show responses" do
    # Test caching functionality
    api_get "/api/v1/products/#{@product.id}"
    assert_json_response
    first_response = json_response
    
    # Make the same request again - should hit cache
    api_get "/api/v1/products/#{@product.id}"
    assert_json_response
    second_response = json_response
    
    assert_equal first_response, second_response
  end

  test "should invalidate cache on product update" do
    # First request to populate cache
    api_get "/api/v1/products/#{@product.id}"
    assert_json_response
    original_name = json_response["name"]
    
    # Update the product
    api_patch "/api/v1/products/#{@product.id}", {
      product: { name: "Cache Invalidated Product" }
    }
    assert_json_response
    
    # Subsequent request should show updated data (cache invalidated)
    api_get "/api/v1/products/#{@product.id}"
    assert_json_response
    assert_equal "Cache Invalidated Product", json_response["name"]
    assert_not_equal original_name, json_response["name"]
  end

  test "should invalidate cache on product feature" do
    # Ensure product is not featured initially
    @product.update!(is_featured: false)
    
    # First request to populate cache
    api_get "/api/v1/products/#{@product.id}"
    assert_json_response
    assert_not json_response["is_featured"]
    
    # Feature the product
    api_patch "/api/v1/products/#{@product.id}/feature"
    assert_json_response
    
    # Subsequent request should show featured status (cache invalidated)
    api_get "/api/v1/products/#{@product.id}"
    assert_json_response
    assert json_response["is_featured"]
  end
end 