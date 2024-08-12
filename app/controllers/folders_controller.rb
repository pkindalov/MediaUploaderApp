# frozen_string_literal: true

class FoldersController < ApplicationController
  before_action :authenticate_user!

  def index
    create_physical_folder_for_user # Създава физическа директория за потребителя, ако не съществува
    @folders = current_user.folders.paginate(page: params[:page], per_page: 40).order('created_at DESC')
  end

  def new
    @folder = current_user.folders.new
  end

  def create
    @folder = current_user.folders.new(folder_params)
    if @folder.save
      create_physical_folder_for_user(@folder) # Създава физическа поддиректория за новата папка
      redirect_to folders_path, notice: "Folder created successfully."
    else
      render :new
    end
  end

  private

  def folder_params
    params.require(:folder).permit(:name)
  end

  def create_physical_folder_for_user(folder = nil)
    root_path = Rails.configuration.user_files_path # Използвай новата променлива
    user_folder_path = File.join(root_path, current_user.email)

    # Създаваме главната папка на потребителя, ако не съществува
    FileUtils.mkdir_p(user_folder_path) unless Dir.exist?(user_folder_path)

    if folder
      # Ако е предоставена папка, създаваме под-директория за нея
      folder_path = File.join(user_folder_path, folder.name)
      FileUtils.mkdir_p(folder_path) unless Dir.exist?(folder_path)
    end
  end
end
