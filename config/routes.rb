# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users

  resources :folders do
    resources :media_files, only: %i[index new create]
  end

  get '/serve_media_file', to: 'downloads#serve', as: 'serve_media_file'
  root to: 'home#index'
end
