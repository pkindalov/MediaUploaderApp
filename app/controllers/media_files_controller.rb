class MediaFilesController < ApplicationController
  before_action :set_folder
  before_action :set_paths
  before_action :set_media_file, only: %i[edit update destroy]

  def index
    @media_files = @folder.media_files.paginate(page: params[:page], per_page: 40).order('created_at DESC')
  end

  def new
    @media_file = @folder.media_files.new
  end

  def create
    if params[:media_file].present? && params[:media_file][:file].present?
      uploaded_file = params[:media_file][:file]
      file_name_with_extension = save_file_to_physical_folder(uploaded_file)
      @media_file = @folder.media_files.new(file: file_name_with_extension)

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

  def edit
  end

  def update
    old_file_name = @media_file.file
    new_file_name = media_file_params[:file]

    if rename_physical_file(old_file_name, new_file_name)
      if @media_file.update(file: new_file_name)
        redirect_to folder_media_files_path(@folder), notice: 'File renamed successfully.'
      else
        Rails.logger.debug "MediaFile errors: #{@media_file.errors.full_messages}"
        render :edit
      end
    else
      redirect_to folder_media_files_path(@folder), alert: 'Failed to rename file.'
    end
  end

  def destroy
    begin
      delete_physical_file(@media_file.file)
    rescue => e
      # Rails.logger.error "Error deleting physical file: #{e.message}"
    ensure
      # Независимо от успеха или провала при изтриването на файла, изтрий записа от базата данни
      @media_file.destroy
      redirect_to folder_media_files_path(@folder), notice: 'File deleted successfully.'
    end
  end

  private

  def set_folder
    @folder = current_user.folders.find(params[:folder_id])
  end

  def set_paths
    root_path = Rails.configuration.user_files_path
    @user_folder_path = File.join(root_path, @folder.user.email, @folder.name)
  end

  def set_media_file
    @media_file = @folder.media_files.find(params[:id])
  end

  def media_file_params
    params.require(:media_file).permit(:file)
  end

  def save_file_to_physical_folder(uploaded_file)
    root_path = Rails.configuration.user_files_path
    user_folder_path = File.join(root_path, @folder.user.email, @folder.name)
    FileUtils.mkdir_p(user_folder_path) unless Dir.exist?(user_folder_path)

    file_name_with_extension = uploaded_file.original_filename
    file_path = File.join(user_folder_path, file_name_with_extension)

    File.open(file_path, "wb") do |file|
      file.write(uploaded_file.read)
    end

    file_name_with_extension
  end

  def rename_physical_file(old_name, new_name)
    old_path = File.join(@user_folder_path, old_name)
    new_path = File.join(@user_folder_path, new_name)

    if File.exist?(old_path) && old_name != new_name
      begin
        File.rename(old_path, new_path)
        true
      rescue => e
        Rails.logger.error "Error renaming file: #{e.message}"
        false
      end
    else
      false
    end
  end

  def delete_physical_file(file_name)
    file_path = File.join(@user_folder_path, file_name)

    if File.exist?(file_path)
      begin
        File.delete(file_path)
        true
      rescue => e
        Rails.logger.error "Error deleting file: #{e.message}"
        false
      end
    else
      Rails.logger.warn "File not found, treating as successful deletion."
      true
    end
  end
end
