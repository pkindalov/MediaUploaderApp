class HomeController < ApplicationController
  def index
    # Извличаме последните 5 качени папки от всички потребители
    @recent_folders = Folder.order(created_at: :desc).limit(5)

    # Извличаме последните 5 качени файла от всички потребители
    @recent_files = MediaFile.includes(:folder).order(created_at: :desc).limit(5)
  end
end
