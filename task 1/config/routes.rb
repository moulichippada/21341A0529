Rails.application.routes.draw do
  get 'numbers/:id', to: 'numbers#show'
end
