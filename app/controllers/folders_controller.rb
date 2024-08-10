class FoldersController < ApplicationController
  before_action :authenticate_user!

  def index
    @folders = current_user.folders
  end

  def new
    @folder = current_user.folders.new
  end

  def create
    @folder = current_user.folders.new(folder_params)
    if @folder.save
      redirect_to folders_path, notice: "Folder created successfully."
    else
      render :new
    end
  end

  private

  def folder_params
    params.require(:folder).permit(:name)
  end
end
