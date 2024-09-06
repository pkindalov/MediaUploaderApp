# frozen_string_literal: true

require 'test_helper'

class FoldersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @root_folder_path = Rails.configuration.user_files_path
    @user_main_folder_path = File.join(@root_folder_path, @user.email)

    # Create a couple of parent folders (parent_id: nil)
    @parent_folder1 = Folder.create!(name: 'Parent Folder 1', user: @user, parent_id: nil)
    @parent_folder2 = Folder.create!(name: 'Parent Folder 2', user: @user, parent_id: nil)

    # Create a child folder (parent_id set to one of the parent folders)
    @child_folder = Folder.create!(name: 'Child Folder', user: @user, parent_id: @parent_folder1.id)

    # @user = User.create!(email: 'testuser@example.com', password: 'password')
    # @controller = FoldersController.new
    # @user = User.find_by(email: 'user@example.com') || User.create!(email: 'user@example.com', password: 'password')
    # @root_folder_path = Rails.configuration.user_files_path
    # @user_main_folder_path = File.join(@root_folder_path, @user.email)

    # Creating user's main directory
    # FileUtils.mkdir_p(@user_main_folder_path)
  end

  test 'should get index' do
    get folders_path
    assert_response :success
    assert Dir.exist?(@user_main_folder_path)
  end

  test 'should fetch parent and child folders for current user' do
    get folders_path
    assert_response :success

    # Fetch the assigned folders in the index view
    folders = assigns(:folders)

    # Ensure parent and child folders are included
    assert_includes folders, @parent_folder1
    assert_includes folders, @parent_folder2
    assert_includes folders, @child_folder # Child folder should be in the flat list of folders
  end



  # test 'experiment' do
  #   assert true
  # end

  # def teardown
  #   FileUtils.rm_rf(@user_main_folder_path) if Dir.exist?(@user_main_folder_path)
  # end

  # def create_folder_structure(base_folder, subfolders)
  #   subfolders.each do |subfolder|
  #     path = File.join(base_folder, subfolder)
  #     FileUtils.mkdir_p(path)
  #     assert Dir.exist?(path)
  #     puts "Created folder: #{path}"
  #   end
  # end

end
