class MediaFilesController < ApplicationController
  before_action :set_folder

  def index
    @media_files = @folder.media_files
  end

  def new
    @media_file = @folder.media_files.new
  end

  def create
    @media_file = @folder.media_files.new(media_file_params)

    if @media_file.save
      redirect_to folder_media_files_path(@folder), notice: "File uploaded successfully."
    else
      render :new
    end
  end

  private

  def set_folder
    @folder = current_user.folders.find(params[:folder_id])
  end

  def media_file_params
    params.require(:media_file).permit(:file)
  end
end
