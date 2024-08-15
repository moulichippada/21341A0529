Rails.application.routes.draw do
  # Other routes...

  # Route to get products
  get 'products', to: 'products#index'
end

