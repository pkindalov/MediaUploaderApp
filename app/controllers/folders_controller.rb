# frozen_string_literal: true

class FoldersController < ApplicationController
  include FolderSizeCalculator
  before_action :authenticate_user!
  before_action :set_folder, only: %i[edit update destroy]

  def index
    create_physical_folder_for_user
    @folders = current_user.folders.paginate(page: params[:page], per_page: 40).order('created_at DESC')
  end

  def list_all_folders
    @folders = Folder.order(created_at: :desc).paginate(page: params[:page],
                                                        per_page: 50).order('created_at DESC')
    @folder_sizes = calculate_folder_sizes(@folders)
    @total_size = calculate_total_size(@folders)
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
    # Първо преименуваме директорията на външния диск
    rename_physical_folder_for_user(@folder)

    if @folder.update(folder_params)
      redirect_to folders_path, notice: 'Folder updated successfully.'
    else
      render :edit
    end
  end

  def destroy
    # Първо изтриваме директорията на външния диск
    delete_physical_folder(@folder)

    @folder.destroy
    redirect_to folders_path, notice: 'Folder deleted successfully.'
  end

  private

  def set_folder
    @folder = current_user.folders.find(params[:id])
  end

  def folder_params
    params.require(:folder).permit(:name)
  end

  def create_physical_folder_for_user(folder = nil)
    root_path = Rails.configuration.user_files_path
    user_folder_path = File.join(root_path, current_user.email)
    FileUtils.mkdir_p(user_folder_path) unless Dir.exist?(user_folder_path)

    if folder
      folder_path = File.join(user_folder_path, folder.name)
      FileUtils.mkdir_p(folder_path) unless Dir.exist?(folder_path)
    end
  end

  def rename_physical_folder_for_user(folder)
    root_path = Rails.configuration.user_files_path
    user_folder_path = File.join(root_path, current_user.email)
    old_folder_path = File.join(user_folder_path, folder.name_was)
    new_folder_path = File.join(user_folder_path, folder_params[:name])

    return unless Dir.exist?(old_folder_path) && old_folder_path != new_folder_path

    temp_folder_path = File.join(user_folder_path, "temp_#{SecureRandom.hex}")

    begin
      # Създаване на временната директория
      FileUtils.mkdir_p(temp_folder_path)

      # Преместване на всеки файл във временната директория
      Dir.glob("#{old_folder_path}/**/*", File::FNM_DOTMATCH).each do |file|
        next if File.directory?(file)

        relative_path = file.sub(old_folder_path, '')
        temp_file_path = File.join(temp_folder_path, relative_path)
        temp_file_dir = File.dirname(temp_file_path)

        # Създаване на директорията, ако не съществува
        FileUtils.mkdir_p(temp_file_dir)

        # Преместване на файла
        begin
          FileUtils.mv(file, temp_file_path)
        rescue Errno::EACCES => e
          Rails.logger.error "Permission denied while moving file #{file}: #{e.message}"
          raise
        end
      end

      # Създаване на новата директория
      FileUtils.mkdir_p(new_folder_path)

      # Преместване на файловете от временната директория в новата
      FileUtils.mv(Dir["#{temp_folder_path}/*"], new_folder_path)

      # Изтриване на старата директория
      FileUtils.rm_rf(old_folder_path)
      FileUtils.rm_rf(temp_folder_path)
    rescue => e
      Rails.logger.error "Error renaming folder: #{e.message}"
      raise
    end
  end

  def delete_physical_folder(folder)
    root_path = Rails.configuration.user_files_path
    user_folder_path = File.join(root_path, current_user.email)
    folder_path = File.join(user_folder_path, folder.name)

    if Dir.exist?(folder_path)
      FileUtils.rm_rf(folder_path) # Изтрива цялата директория и съдържанието й
    end
  end
end
