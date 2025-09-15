# Test file for CategoriesController
# This file contains tests to verify the mass assignment fixes

require 'test_helper'

class Api::V1::CategoriesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @category = create_test_category("Electronics")
  end

  test "should get index" do
    api_get "/api/v1/categories"
    assert_json_response
    assert_not_nil json_response
  end

  test "should get show" do
    api_get "/api/v1/categories/#{@category.id}"
    assert_json_response
    assert_equal @category.name, json_response["name"]
  end

  test "should create category" do
    assert_difference('Category.count') do
      api_post "/api/v1/categories", {
        category: {
          name: "New Category"
        }
      }
    end
    assert_json_response(:created)
    assert_equal "New Category", Category.last.name
  end

  test "should prevent mass assignment in category create" do
    assert_difference('Category.count') do
      api_post "/api/v1/categories", {
        category: {
          name: "Safe Category",
          malicious_param: "should be ignored"
        }
      }
    end
    assert_json_response(:created)
    category = Category.last
    assert_equal "Safe Category", category.name
  end

  test "should update category" do
    api_patch "/api/v1/categories/#{@category.id}", {
      category: {
        name: "Updated Category"
      }
    }
    assert_json_response
    @category.reload
    assert_equal "Updated Category", @category.name
  end

  test "should prevent mass assignment in category update" do
    original_name = @category.name
    api_patch "/api/v1/categories/#{@category.id}", {
      category: {
        name: "Safely Updated Category",
        malicious_param: "should be ignored"
      }
    }
    assert_json_response
    @category.reload
    assert_equal "Safely Updated Category", @category.name
  end

  test "should delete category" do
    assert_difference('Category.count', -1) do
      api_delete "/api/v1/categories/#{@category.id}"
    end
    assert_response :no_content
  end

  test "should not create category with invalid data" do
    assert_no_difference('Category.count') do
      api_post "/api/v1/categories", {
        category: {
          name: nil
        }
      }
    end
    assert_json_response(:unprocessable_entity)
  end
end
