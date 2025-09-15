# This controller is designed to have multiple bugs:
# 1. N+1 Query (part of Bug 2.1): The `index` action fetches products without eager loading categories.
# 2. Mass Assignment Vulnerability (Bug 2.2): The `create` and `update` actions use `params.permit!`
#    or directly assign `params[:product]`, making them vulnerable.
# 3. Stale Price/Data Caching (Bug 2.3): The `show` action uses simple action caching without proper invalidation.
module Api
  module V1
    class ProductsController < ApplicationController
      # GET /api/v1/products
      def index
        # BUG 2.1: This will cause an N+1 query problem.
        # For each product, a separate query will be made to fetch its category.
        # Also, if a product's category_id points to a non-existent category,
        # category_name will be nil, which is also part of the bug description.
        # @products = Product.all
        @products = Product.includes(:category).all

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
        
        cached_product = Rails.cache.fetch("product_#{@product.id}", expires_in: 5.minutes) do
          {
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
        
        render json: cached_product
      end

      # POST /api/v1/products
      def create
        @product = Product.new(product_params) # USING STRONG PARAMETERS

        if @product.save
          render json: @product, status: :created
        else
          render json: @product.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/products/:id
      def update
        @product = Product.find(params[:id])
        if @product.update(product_params) # USING STRONG PARAMETERS
          Rails.cache.delete("product_#{@product.id}")
          render json: @product
        else
          render json: @product.errors, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/products/:id
      def destroy
        @product = Product.find(params[:id])
        Rails.cache.delete("product_#{@product.id}")
        @product.destroy
        head :no_content
      end

      # Custom action for featuring a product (for Task 3.2)
      def feature
        @product = Product.find(params[:id])
        if @product.update(is_featured: true)
          Rails.cache.delete("product_#{@product.id}")
          render json: @product
        else
          render json: @product.errors, status: :unprocessable_entity
        end
      end

      private

      def product_params
        params.require(:product).permit(:name, :description, :price, :stock_quantity, :category_id, :published_at, :is_featured)
        # Note: :is_admin is intentionally excluded to prevent privilege escalation
      end
    end
  end
end 