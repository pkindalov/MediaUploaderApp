class MediaFilesController < ApplicationController
  before_action :set_folder

  def index
    @media_files = @folder.media_files
  end

  def new
    @media_file = @folder.media_files.new
  end

  def create
    if params[:media_file].present? && params[:media_file][:file].present?
      uploaded_file = params[:media_file][:file]
      save_file_to_physical_folder(uploaded_file)
      @media_file = @folder.media_files.new(file: uploaded_file.original_filename)

      if @media_file.save
        redirect_to folder_media_files_path(@folder), notice: "File uploaded successfully."
      else
        Rails.logger.debug "MediaFile errors: #{@media_file.errors.full_messages}"
        render :new
      end
    else
      render :new, alert: "Please select a file to upload."
    end
  end

  private

  def set_folder
    @folder = current_user.folders.find(params[:folder_id])
  end

  def media_file_params
    params.require(:media_file).permit(:file)
  end

  def save_file_to_physical_folder(uploaded_file)
    root_path = Rails.configuration.user_files_path # Използвай новата променлива
    user_folder_path = File.join(root_path, @folder.user.email, @folder.name)
    FileUtils.mkdir_p(user_folder_path) unless Dir.exist?(user_folder_path)

    file_path = File.join(user_folder_path, uploaded_file.original_filename)
    File.open(file_path, "wb") do |file|
      file.write(uploaded_file.read)
    end
  end
end
