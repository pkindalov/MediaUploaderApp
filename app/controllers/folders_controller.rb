# frozen_string_literal: true

class FoldersController < ApplicationController
  include FolderSizeCalculator
  before_action :authenticate_user!
  before_action :set_folder, only: %i[edit update destroy]

  def index
    create_physical_folder_for_user

    # Fetch all parent folders for the current user
    parent_folders = current_user.folders.where(parent_id: nil).order('created_at DESC')

    # Recursively fetch all folders with their children and store in a flat array
    all_folders = []
    parent_folders.each do |parent_folder|
      add_folder_with_children(parent_folder, all_folders)
    end

    # Paginate the folders
    total_folders_count = all_folders.size
    page = params[:page] || 1
    @folders = WillPaginate::Collection.create(page, 40, total_folders_count) do |pager|
      start = (pager.current_page - 1) * pager.per_page
      pager.replace(all_folders[start, pager.per_page] || [])
    end

    @folder_sizes = calculate_total_folder_sizes(@folders)
  end

  def list_all_folders
    # Fetch all parent folders
    parent_folders = Folder.where(parent_id: nil).order(created_at: :desc)

    # Recursively fetch all folders with their children and store in a flat array
    all_folders = []
    parent_folders.each do |parent_folder|
      add_folder_with_children(parent_folder, all_folders)
    end

    total_folders_count = all_folders.size
    page = (params[:page] || 1).to_i
    per_page = 50
    max_page = (total_folders_count.to_f / per_page).ceil

    # Redirect to the last page if the requested page exceeds the max page
    if page > max_page && max_page > 0
      redirect_to list_folders_path(page: max_page), alert: 'Няма повече записи' and return
    elsif total_folders_count == 0
      set_flash_message!(:notice, 'Няма налични папки.')
    end

    # Paginate the folders
    @folders = WillPaginate::Collection.create(page, per_page, total_folders_count) do |pager|
      start = (pager.current_page - 1) * pager.per_page
      pager.replace(all_folders[start, pager.per_page])
    end

    @folder_sizes = calculate_total_folder_sizes(@folders)
    @total_size = number_to_human_size(@folder_sizes.values.sum)
  end

  def new
    @folder = current_user.folders.new
  end

  def create
    @folder = current_user.folders.new(folder_params)
    if @folder.save
      create_physical_folder_for_user(@folder)
      redirect_to folders_path, notice: 'Folder created successfully.'
    else
      render :new
    end
  end

  def edit; end

  def update
    if folder_params[:name] != @folder.name || folder_params[:parent_id] != @folder.parent_id
      rename_physical_folder_for_user(@folder)
    end

    if @folder.update(folder_params)
      redirect_to folders_path, notice: 'Folder updated successfully.'
    else
      render :edit
    end
  end

  def destroy
    if @folder.nil?
      redirect_to folders_path, alert: 'Folder not found.'
      return
    end

    Rails.logger.info "Attempting to delete folder with ID: #{@folder.id}"

    begin
      delete_descendants(@folder)
    rescue => e
      Rails.logger.error "Failed to delete descendant folders: #{e.message}"
      redirect_to folders_path, alert: 'Failed to delete descendant folders.'
      return
    end

    begin
      delete_physical_folder(@folder)
    rescue => e
      Rails.logger.error "Failed to delete physical folder: #{e.message}"
      redirect_to folders_path, alert: 'Failed to delete the physical folder.'
      return
    end

    if @folder.destroy
      Rails.logger.info "Folder successfully deleted from the database with ID: #{@folder.id}"
      redirect_to folders_path, notice: 'Folder deleted successfully.'
    else
      Rails.logger.error "Failed to delete folder from database: #{@folder.errors.full_messages.join(', ')}"
      redirect_to folders_path, alert: 'Failed to delete the folder from the database.'
    end
  end

  private

  def set_folder
    @folder = current_user.folders.find_by(id: params[:id])
    if @folder.nil?
      redirect_to folders_path, alert: 'Folder not found.'
    end
  end

  def folder_params
    params.require(:folder).permit(:name, :parent_id)
  end

  def create_physical_folder_for_user(folder = nil)
    root_path = Rails.configuration.user_files_path
    user_folder_path = File.join(root_path, current_user.email)

    if folder
      parent_folder_path = folder.parent ? File.join(user_folder_path, build_path_for_parent(folder.parent)) : user_folder_path
      folder_path = File.join(parent_folder_path, folder.name)
      FileUtils.mkdir_p(folder_path) unless Dir.exist?(folder_path)
    else
      FileUtils.mkdir_p(user_folder_path) unless Dir.exist?(user_folder_path)
    end
  end

  def rename_physical_folder_for_user(folder)
    root_path = Rails.configuration.user_files_path
    user_folder_path = File.join(root_path, current_user.email)

    old_folder_path = File.join(user_folder_path, build_path_for_parent(folder_was_parent(folder)), folder.name_was.presence || 'Default Folder')
    new_folder_name = folder_params[:name].presence || folder.name.presence || 'Default Folder'
    new_folder_path = File.join(user_folder_path, build_path_for_parent(Folder.find_by(id: folder_params[:parent_id])), new_folder_name)

    # Log the folder paths for debugging
    Rails.logger.info "Old Folder Path: #{old_folder_path}"
    Rails.logger.info "New Folder Path: #{new_folder_path}"

    return if old_folder_path == new_folder_path

    FileUtils.mkdir_p(File.dirname(new_folder_path)) unless Dir.exist?(File.dirname(new_folder_path))

    begin
      if Dir.exist?(old_folder_path)
        FileUtils.mv(old_folder_path, new_folder_path)
        Rails.logger.info "Folder moved from #{old_folder_path} to #{new_folder_path}"
      else
        Rails.logger.error "Old folder path does not exist: #{old_folder_path}"
      end
    rescue => e
      Rails.logger.error "Error moving folder: #{e.message}"
      raise
    end
  end





  def folder_was_parent(folder)
    Folder.find_by(id: folder.parent_id_was)
  end

  def build_path_for_parent(parent_folder)
    parent_folder ? File.join(build_path_for_parent(parent_folder.parent), parent_folder.name) : ''
  end

  def delete_descendants(folder)
    folder.subfolders.each do |subfolder|
      delete_descendants(subfolder)
      delete_physical_folder(subfolder)
      subfolder.destroy
    end
  end

  def delete_physical_folder(folder)
    root_path = Rails.configuration.user_files_path
    user_folder_path = File.join(root_path, folder.user.email)
    folder_path = File.join(user_folder_path, build_path_for_parent(folder.parent), folder.name)

    FileUtils.rm_rf(folder_path) if Dir.exist?(folder_path)
  end
end
