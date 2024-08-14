Rails.application.routes.draw do
  devise_for :users

  get '/folders/listAllFolders', to: 'folders#list_all_folders', as: 'list_folders'
  get '/mediaFiles/listAllFiles', to: 'media_files#list_all_files', as: 'list_files'

  resources :folders do
    resources :media_files, only: %i[index new create edit update destroy] do
      member do
        get :watch # Добавяме нов маршрут за гледане на видеото
      end
    end
  end

  get '/serve_media_file', to: 'downloads#serve', as: 'serve_media_file'
  root to: 'home#index'
end
