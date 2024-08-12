# frozen_string_literal: true

class MediaFilesController < ApplicationController
  before_action :set_folder
  before_action :set_paths

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


  private

  def set_folder
    @folder = current_user.folders.find(params[:folder_id])
  end

  def set_paths
    root_path = Rails.configuration.user_files_path
    @user_folder_path = File.join(root_path, @folder.user.email, @folder.name)
  end

  def media_file_params
    params.require(:media_file).permit(:file)
  end

  def save_file_to_physical_folder(uploaded_file)
    root_path = Rails.configuration.user_files_path
    user_folder_path = File.join(root_path, @folder.user.email, @folder.name)
    FileUtils.mkdir_p(user_folder_path) unless Dir.exist?(user_folder_path)

    # Извличане на оригиналното име на файла с разширението
    file_name_with_extension = uploaded_file.original_filename
    file_path = File.join(user_folder_path, file_name_with_extension)

    # Записване на файла на външния диск
    File.open(file_path, "wb") do |file|
      file.write(uploaded_file.read)
    end

    # Връщане на името на файла с разширението
    file_name_with_extension
  end






end
