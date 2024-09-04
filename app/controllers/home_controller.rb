# app/controllers/home_controller.rb
class HomeController < ApplicationController
  include FolderSizeCalculator
  include FileSorting

  def index
    if current_user
      # Fetch parent folders and organize folders like in list_all_folders
      parent_folders = Folder.where(parent_id: nil).order(created_at: :desc)

      all_folders = []
      parent_folders.each do |parent_folder|
        add_folder_with_children(parent_folder, all_folders)
      end

      # Limit the number of folders to display
      @recent_folders = all_folders.take(5)

      @recent_files = sort_files_by_availability(MediaFile.order(created_at: :desc).limit(5))
      disk_mount_point = ENV.fetch('DISK_MOUNT_POINT', 'E:/')
      @disk_usage = calculate_disk_usage(disk_mount_point)
      @folder_sizes = calculate_total_folder_sizes(@recent_folders)
    end
  end

  private

  def calculate_disk_usage(mount_point)
    begin
      stat = Sys::Filesystem.stat(mount_point)
      total_bytes = stat.blocks * stat.block_size
      free_bytes = stat.blocks_available * stat.block_size
      used_bytes = total_bytes - free_bytes
      percent_used = (used_bytes.to_f / total_bytes) * 100
      percent_free = 100 - percent_used

      {
        total: bytes_to_human(total_bytes),
        free: bytes_to_human(free_bytes),
        used: bytes_to_human(used_bytes),
        percent_used: percent_used.round(2),
        percent_free: percent_free.round(2)
      }
    rescue Errno::ESRCH, Errno::ENOENT => e
      Rails.logger.error "Error calculating disk usage: #{e.message}"
      nil
    end
  end

  def bytes_to_human(bytes)
    units = ['B', 'KB', 'MB', 'GB', 'TB']
    e = (Math.log(bytes) / Math.log(1024)).floor
    s = "%.2f" % (bytes.to_f / 1024 ** e)
    "#{s} #{units[e]}"
  end

end
