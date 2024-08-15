# app/controllers/numbers_controller.rb
require 'httparty'
require 'json'

class NumbersController < ApplicationController
  Ws = 10
  THIRD_PARTY_API_URL = 'https://example.com/api/numbers'
  
  before_action :fetch_numbers

  # GET /numbers/:id
  def show
    start_time = Time.now
    number_id = params[:id]
    new_numbers = fetch_numbers_from_api(number_id)
    if new_numbers.nil? || new_numbers.empty?
      render json: { error: 'Failed to fetch numbers or invalid ID' }, status: :unprocessable_entity
      return
    end
    store_numbers(new_numbers)
    window_prev_state = @stored_numbers.dup
    @stored_numbers = @stored_numbers.last(Ws) 
    avg = calculate_average(@stored_numbers) 
    response_time = Time.now - start_time
    if response_time > 0.5
      render json: { error: 'Response time exceeded 500ms' }, status: :timeout
      return
    end
    render json: {
      windowPrevState: window_prev_state,
      windowCurrState: @stored_numbers,
      numbers: new_numbers,
      avg: avg
    }
  end

  private
  def fetch_numbers_from_api(number_id)
    begin
      Rails.logger.info("Attempting to fetch numbers with ID: #{number_id}")
      response = HTTParty.get("#{THIRD_PARTY_API_URL}?id=#{number_id}", timeout: 5)
      Rails.logger.info("Response Code: #{response.code}")
      
      if response.code == 200
        begin
          numbers = JSON.parse(response.body)['numbers']
          Rails.logger.info("Fetched numbers: #{numbers}")
          return numbers
        rescue JSON::ParserError => e
          Rails.logger.error("JSON Parsing Error: #{e.message}")
          return nil
        end
      else
        Rails.logger.error("API returned non-200 status code: #{response.code}")
        return nil
      end
    rescue HTTParty::Error => e
      Rails.logger.error("HTTParty Error: #{e.message}")
      return nil
    rescue Net::OpenTimeout => e
      Rails.logger.error("Network Timeout Error: #{e.message}")
      return nil
    end
  end
  
  
  def fetch_numbers
    @stored_numbers = Rails.cache.fetch('stored_numbers', expires_in: 1.hour) { [] }
  end

  def store_numbers(new_numbers)
    unique_numbers = (new_numbers.uniq - @stored_numbers).first(Ws - @stored_numbers.size)
    @stored_numbers += unique_numbers
    @stored_numbers = @stored_numbers.last(Ws) 
    Rails.cache.write('stored_numbers', @stored_numbers, expires_in: 1.hour)
  end

  def calculate_average(numbers)
    return 0 if numbers.empty?
    numbers.sum / numbers.size.to_f
  end
end
