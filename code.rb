# app/models/product.rb
# This model has a `belongs_to` association that, combined with the controller,
# can lead to the N+1 problem and `nil` category names.
class Product < ApplicationRecord
    # BUG: `optional: true` allows products without a category.
    # This combined with the N+1 in the controller will manifest the bug.
    belongs_to :category, optional: true
  
    # Additional attributes for the challenge:
    # name:string
    # description:text
    # price:decimal
    # stock_quantity:integer
    # category_id:integer (foreign key to Category)
    # published_at:datetime
    # is_featured:boolean (default to false)
    # is_admin:boolean (default to false, for mass assignment vulnerability demo)
  
    validates :name, presence: true
    validates :price, numericality: { greater_than_or_equal_to: 0 }
    validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }
  
    # Example method to get category name (controller will call this)
    # The `&.` (safe navigation) handles nil, but doesn't fix the N+1 or
    # underlying data issue if category_id points to a non-existent category.
    def category_name
      category&.name
    end
  end
  
  ```ruby
  # app/models/category.rb
  # A simple category model.
  class Category < ApplicationRecord
    has_many :products
  
    # name:string
    validates :name, presence: true, uniqueness: true
  end
  
  ```ruby
  # app/controllers/api/v1/products_controller.rb
  # This controller is designed to have multiple bugs:
  # 1. N+1 Query (part of Bug 2.1): The `index` action fetches products without eager loading categories.
  # 2. Mass Assignment Vulnerability (Bug 2.2): The `create` and `update` actions use `params.permit!`
  #    or directly assign `params[:product]`, making them vulnerable.
  # 3. Stale Price/Data Caching (Bug 2.3): The `show` action uses simple action caching without proper invalidation.
  module Api
    module V1
      class ProductsController < ApplicationController
        # BUG 2.3 (Part 1): Basic action caching without proper invalidation.
        # This cache will not be automatically busted when a product is updated.
        # Requires `gem 'actionpack-action_caching'` to be installed and configured.
        caches_action :show, expires_in: 5.minutes
  
        # GET /api/v1/products
        def index
          # BUG 2.1: This will cause an N+1 query problem.
          # For each product, a separate query will be made to fetch its category.
          # Also, if a product's category_id points to a non-existent category,
          # category_name will be nil, which is also part of the bug description.
          @products = Product.all
  
          # Simplified JSON rendering for illustration.
          # In a real app, you'd typically use serializers (e.g., Active Model Serializers, jbuilder).
          render json: @products.map { |product|
            {
              id: product.id,
              name: product.name,
              description: product.description,
              price: product.price,
              stock_quantity: product.stock_quantity,
              category_id: product.category_id,
              category_name: product.category_name, # This call triggers the N+1 query
              published_at: product.published_at,
              is_featured: product.is_featured,
              is_admin: product.is_admin # Exposing this for the mass assignment demo
            }
          }
        end
  
        # GET /api/v1/products/:id
        def show
          @product = Product.find(params[:id])
          render json: {
            id: @product.id,
            name: @product.name,
            description: @product.description,
            price: @product.price,
            stock_quantity: @product.stock_quantity,
            category_id: @product.category_id,
            category_name: @product.category_name,
            published_at: @product.published_at,
            is_featured: @product.is_featured,
            is_admin: @product.is_admin
          }
        end
  
        # POST /api/v1/products
        def create
          # BUG 2.2: Mass assignment vulnerability.
          # This allows any attribute in the `product` hash to be set,
          # including potentially malicious or unintended ones (e.g., `is_admin`).
          @product = Product.new(params[:product]) # DIRECT ASSIGNMENT FROM PARAMS
  
          if @product.save
            render json: @product, status: :created
          else
            render json: @product.errors, status: :unprocessable_entity
          end
        end
  
        # PATCH/PUT /api/v1/products/:id
        def update
          @product = Product.find(params[:id])
          # BUG 2.2: Mass assignment vulnerability.
          # This allows any attribute in the `product` hash to be set,
          # including potentially malicious or unintended ones.
          if @product.update(params.permit!) # USING permit! which is unsafe
            # BUG 2.3 (Part 2): Cache invalidation missing.
            # The `show` action's cache is not explicitly expired here by default.
            # You would add `expire_action action: :show, id: @product.id` as a fix.
            render json: @product
          else
            render json: @product.errors, status: :unprocessable_entity
          end
        end
  
        # DELETE /api/v1/products/:id
        def destroy
          @product = Product.find(params[:id])
          @product.destroy
          head :no_content
        end
  
        # Custom action for featuring a product (for Task 3.2)
        def feature
          @product = Product.find(params[:id])
          if @product.update(is_featured: true)
            # BUG 2.3 (Part 3): Cache invalidation missing for custom actions as well.
            # The `show` action's cache is not explicitly expired here by default.
            # You would add `expire_action action: :show, id: @product.id` as a fix.
            render json: @product
          else
            render json: @product.errors, status: :unprocessable_entity
          end
        end
  
        # Private method for strong parameters (this would be the fix for Bug 2.2)
        # private
        # def product_params
        #   params.require(:product).permit(:name, :description, :price, :stock_quantity, :category_id, :published_at, :is_featured)
        # end
      end
    end
  end
  
  ```ruby
  # config/routes.rb
  # This routes file sets up the basic API endpoints.
  Rails.application.routes.draw do
    # The priority is based upon order of creation: first created -> highest priority.
    # See how all your routes lay out with "rake routes".
  
    # Define API routes under a namespace for versioning
    namespace :api do
      namespace :v1 do
        resources :products do
          # Custom member route for featuring a product (for Task 3.2)
          # This route is correctly defined, but the controller action needs fixing.
          patch :feature, on: :member
        end
        resources :categories, only: [:index, :show] # Basic category routes
      end
    end
  
    # Health check endpoint (example from provided `rails-frontend`)
    get 'health' => 'application#health'
  
    # Root URL (example from provided `rails-frontend`)
    root 'application#index'
  end
  
  ```ruby
  # db/migrate/<timestamp>_create_products.rb
  # You would need to run `rails db:migrate` after creating these.
  class CreateProducts < ActiveRecord::Migration[5.0] # Adjust migration version if needed
    def change
      create_table :products do |t|
        t.string :name, null: false
        t.text :description
        t.decimal :price, precision: 10, scale: 2, default: 0.0
        t.integer :stock_quantity, default: 0
        t.references :category, foreign_key: true # This will create category_id column
        t.datetime :published_at
        t.boolean :is_featured, default: false # For the featuring task
        # Add a potential malicious attribute for mass assignment bug demo
        t.boolean :is_admin, default: false # This is the "phantom feature" attribute
  
        t.timestamps
      end
    end
  end
  
  ```ruby
  # db/migrate/<timestamp>_create_categories.rb
  class CreateCategories < ActiveRecord::Migration[5.0] # Adjust migration version if needed
    def change
      create_table :categories do |t|
        t.string :name, null: false, unique: true
  
        t.timestamps
      end
    end
  end
  
  ```ruby
  # db/seeds.rb
  # This file will populate your database with some initial data,
  # including products with missing categories to demonstrate the N+1 bug.
  # Clear existing data
  Product.destroy_all
  Category.destroy_all
  
  # Create categories
  electronics = Category.create!(name: 'Electronics')
  books = Category.create!(name: 'Books')
  clothing = Category.create!(name: 'Clothing')
  
  # Create products
  Product.create!([
    {
      name: 'Laptop Pro X',
      description: 'Powerful laptop for professionals.',
      price: 1200.00,
      stock_quantity: 50,
      category: electronics,
      published_at: Time.current
    },
    {
      name: 'The Great Novel',
      description: 'A captivating story.',
      price: 15.99,
      stock_quantity: 200,
      category: books,
      published_at: Time.current
    },
    {
      name: 'Wireless Headphones',
      description: 'High-fidelity sound.',
      price: 79.99,
      stock_quantity: 150,
      category: electronics,
      published_at: 1.day.ago
    },
    {
      name: 'Vintage T-Shirt',
      description: 'Comfortable cotton tee.',
      price: 25.00,
      stock_quantity: 100,
      category: clothing,
      published_at: Time.current,
      is_featured: true
    },
    {
      name: 'Product With Missing Category', # This product will have category_id: nil
      description: 'This product has no assigned category, demonstrating the nil issue.',
      price: 10.00,
      stock_quantity: 10,
      # category_id is explicitly nil here, or you can omit `category:` to make it nil
      category_id: nil,
      published_at: Time.current
    },
    {
      name: 'Another Book',
      description: 'Another great read.',
      price: 12.50,
      stock_quantity: 75,
      category: books,
      published_at: 2.days.ago
    },
    # For demonstrating mass assignment vulnerability, you can imagine
    # this product being created or updated with `is_admin: true` from the API.
    {
      name: 'Secret Admin Product',
      description: 'Only admins should manage this.',
      price: 999.00,
      stock_quantity: 1,
      category: electronics,
      published_at: Time.current,
      is_admin: false # This would be flipped by the bug if exposed via mass assignment.
    }
  ])
  
  puts "Seeding complete! Created #{Product.count} products and #{Category.count} categories."
  
  