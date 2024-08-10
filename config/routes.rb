Rails.application.routes.draw do
  devise_for :users
  root to: 'home#index'
  resources :folders do
    resources :media_files, only: [:new, :create, :index]
  end

end
