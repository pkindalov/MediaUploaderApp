# frozen_string_literal: true

require 'exifr/jpeg'

class MediaFilesController < ApplicationController
  include FolderSizeCalculator
  include FileSorting
  before_action :set_folder, except: ['list_all_files']
  before_action :set_paths, except: ['list_all_files']
  before_action :set_media_file, only: %i[edit update destroy watch]
  before_action :authenticate_user!, except: %i[index watch]

  def index
    media_files = @folder.media_files.order('created_at DESC')
    sorted_files = sort_files_by_availability(media_files)

    # Уверяваме се, че sorted_files е масив, дори и да няма файлове
    sorted_files ||= []

    @media_files = WillPaginate::Collection.create(params[:page] || 1, 40, sorted_files.size) do |pager|
      # Ако sorted_files е празен, pager.offset и pager.per_page ще бъдат безопасни
      pager.replace(sorted_files[pager.offset, pager.per_page].to_a)
    end

    @exif_data = extract_exif_data
    @folder_size = calculate_single_folder_size(@folder)
  end

  def list_all_files
    files = MediaFile.order(created_at: :desc)
    sorted_files = sort_files_by_availability(files)

    # Уверяваме се, че sorted_files е масив, дори и да няма файлове
    sorted_files ||= []

    @files = WillPaginate::Collection.create(params[:page] || 1, 50, sorted_files.size) do |pager|
      pager.replace(sorted_files[pager.offset, pager.per_page].to_a)
    end
  end

  def new
    if @folder.user == current_user
      @media_file = @folder.media_files.new
    else
      redirect_to folder_media_files_path(@folder), alert: 'Нямате права да качвате файлове в тази папка.'
    end
  end

  def create
    if @folder.user == current_user
      if params[:media_file].present? && params[:media_file][:files].present?
        # Пропускане на празни стойности преди проверката
        valid_files = params[:media_file][:files].reject(&:blank?)

        if valid_files.size > ENV.fetch('MAX_FILES_UPLOAD_AT_ONCE').to_i
          redirect_to new_folder_media_file_path(@folder), alert: "Можете да качвате до #{ENV.fetch('MAX_FILES_UPLOAD_AT_ONCE')} файла наведнъж."
          return
        end

        valid_files.each do |uploaded_file|
          file_name_with_extension = save_file_to_physical_folder(uploaded_file)
          @media_file = @folder.media_files.new(file: file_name_with_extension)

          unless @media_file.save
            Rails.logger.debug "MediaFile errors: #{@media_file.errors.full_messages}"
            render :new and return
          end
        end
        redirect_to folder_media_files_path(@folder), notice: "Файловете бяха успешно качени."
      else
        render :new, alert: "Моля, изберете поне един файл за качване."
      end
    else
      redirect_to folder_media_files_path(@folder), alert: 'Нямате права да качвате файлове в тази папка.'
    end
  end

  def edit
    authorize_user_for_media_file!
  end

  def update
    authorize_user_for_media_file!

    old_file_name = @media_file.file
    new_file_name = media_file_params[:file]

    if rename_physical_file(old_file_name, new_file_name)
      if @media_file.update(file: new_file_name)
        redirect_to folder_media_files_path(@folder), notice: 'Файлът е преименуван успешно.'
      else
        Rails.logger.debug "MediaFile errors: #{@media_file.errors.full_messages}"
        render :edit
      end
    else
      redirect_to folder_media_files_path(@folder), alert: 'Неуспешно преименуване на файлът.'
    end
  end

  def destroy
    authorize_user_for_media_file!
    return if performed? # Това ще прекрати изпълнението на метода, ако вече има извикване на redirect_to

    success = true

    begin
      success &&= delete_physical_file(@media_file.file)
    rescue => e
      Rails.logger.error "Error deleting physical file: #{e.message}"
      success = false
    ensure
      success &&= @media_file.destroy
    end

    if success
      redirect_to folder_media_files_path(@folder), notice: "Media file was successfully deleted."
    else
      redirect_to folder_media_files_path(@folder), alert: "Failed to delete the media file."
    end
  end

  def watch
    # Изгледът ще се използва за визуализиране на видеото в нов таб
  end

  private

  def set_folder
    @folder = Folder.find(params[:folder_id])
  end

  def set_paths
    root_path = Rails.configuration.user_files_path
    @user_folder_path = File.join(root_path, @folder.user.email, @folder.name)
  end

  def set_media_file
    @media_file = @folder.media_files.find(params[:id])
  end

  def media_file_params
    params.require(:media_file).permit(:file, :files)
  end

  def authorize_user_for_media_file!
    unless @media_file.folder.user == current_user
      redirect_to root_path
      return
    end
  end

  def save_file_to_physical_folder(uploaded_file)
    root_path = Rails.configuration.user_files_path
    user_folder_path = File.join(root_path, @folder.user.email, @folder.name)
    FileUtils.mkdir_p(user_folder_path) unless Dir.exist?(user_folder_path)

    file_name_with_extension = uploaded_file.original_filename
    file_path = File.join(user_folder_path, file_name_with_extension)

    File.open(file_path, 'wb') do |file|
      file.write(uploaded_file.read)
    end

    file_name_with_extension
  end

  def rename_physical_file(old_name, new_name)
    return false if old_name.nil? || new_name.nil?

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
      Rails.logger.warn 'File not found, treating as successful deletion.'
      true
    end
  end

  def extract_exif_data
    exif_data = {}
    @folder.media_files.each do |media_file|
      file_path = File.join(@user_folder_path, media_file.file)
      next unless ['.jpg', '.jpeg'].include?(File.extname(file_path).downcase)

      begin
        exif = EXIFR::JPEG.new(file_path)
        if exif
          exif_data[media_file.id] = {
            date_time_original: exif.date_time_original,
            f_number: exif.f_number,
            exposure_time: exif.exposure_time.to_s,
            iso_speed_ratings: exif.iso_speed_ratings
          }
        end
      rescue => e
        Rails.logger.error "Error extracting EXIF data: #{e.message}"
      end
    end
    exif_data
  end
end
