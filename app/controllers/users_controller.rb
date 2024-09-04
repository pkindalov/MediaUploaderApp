# app/controllers/users_controller.rb
class UsersController < ApplicationController
  include FileSorting
  include MediaFilter
  include FolderSizeCalculator # Include FolderSizeCalculator for folder hierarchy
  before_action :set_user, only: [:show]

  def show
    # Fetch all parent folders
    parent_folders = @user.folders.where(parent_id: nil).order('created_at DESC')

    # Recursively fetch all folders with their children and store in a flat array
    all_folders = []
    parent_folders.each do |parent_folder|
      add_folder_with_children(parent_folder, all_folders)
    end

    total_folders_count = all_folders.size
    folders_page = (params[:folders_page] || 1).to_i
    folders_per_page = 50
    max_folders_page = (total_folders_count.to_f / folders_per_page).ceil

    # Display a flash message if the requested page exceeds the max page
    if folders_page > max_folders_page && max_folders_page > 0
      flash.now[:alert] = 'Няма повече папки на тази страница.'
      folders_page = max_folders_page # Stay on the last page
    elsif total_folders_count == 0
      flash.now[:notice] = 'Няма качени папки.'
    end

    # Paginate the folders
    @folders = WillPaginate::Collection.create(folders_page, folders_per_page, total_folders_count) do |pager|
      start = (pager.current_page - 1) * pager.per_page
      pager.replace(all_folders[start, pager.per_page])
    end

    # Calculate folder sizes
    @folder_sizes = calculate_total_folder_sizes(@folders)

    # Handle media files with sorting and filtering
    media_files = @user.media_files.order('created_at DESC')
    sorted_files = sort_files_by_availability(media_files)
    sorted_files = filter_media_files(sorted_files, params[:filter]) # Apply the filter by file type
    sorted_files ||= []

    total_files_count = sorted_files.size
    files_page = (params[:files_page] || 1).to_i
    files_per_page = 50
    max_files_page = (total_files_count.to_f / files_per_page).ceil

    # Display a flash message if the requested page exceeds the max page
    if files_page > max_files_page && max_files_page > 0
      flash.now[:alert] = 'Няма повече файлове на тази страница.'
      files_page = max_files_page # Stay on the last page
    elsif total_files_count == 0
      flash.now[:notice] = 'Няма качени файлове.'
    end

    @media_files = WillPaginate::Collection.create(files_page, files_per_page, total_files_count) do |pager|
      start = (pager.current_page - 1) * pager.per_page
      pager.replace(sorted_files[start, pager.per_page].to_a)
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Потребителят не беше намерен.'
  end
end
