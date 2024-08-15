require 'httparty'
require 'json'

class ProductsController < ApplicationController
  URL = 'http://20.244.56.144/test'

  # GET /products
  def index
    company = params[:companyname]
    category = params[:category]
    top = params[:top] || 10
    min_price = params[:minPrice] || 0
    max_price = params[:maxPrice] || 10000
    
    response = fetch_products(company, category, top, min_price, max_price)
    
    if response.nil? || response['products'].empty?
      render json: { error: 'No products found or failed to fetch data' }, status: :not_found
    else
      render json: response
    end
  end

  private

  # Fetch products from the external API
  def fetch_products(company, category, top, min_price, max_price)
    begin
      url = "#{URL}/companies/#{company}/categories/#{category}?top=#{top}&minPrice=#{min_price}&maxPrice=#{max_price}"
      Rails.logger.info("Fetching products from URL: #{url}")
      response = HTTParty.get(url, timeout: 5)
      Rails.logger.info("Response Code: #{response.code}")
      
      if response.code == 200
        JSON.parse(response.body)
      else
        Rails.logger.error("API returned non-200 status code: #{response.code}")
        nil
      end
    rescue HTTParty::Error => e
      Rails.logger.error("HTTParty Error: #{e.message}")
      nil
    rescue JSON::ParserError => e
      Rails.logger.error("JSON Parsing Error: #{e.message}")
      nil
    rescue => e
      Rails.logger.error("Unexpected Error: #{e.message}")
      nil
    end
  end
end
