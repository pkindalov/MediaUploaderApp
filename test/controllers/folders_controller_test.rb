# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

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

  test 'should paginate folders correctly' do
    # Ensure there are no pre-existing folders
    Folder.where(user: @user).destroy_all

    # Create exactly 45 folders for the test
    45.times { |i| Folder.create!(name: "Folder #{i+1}", user: @user) }

    # Fetch the first page (default is page 1)
    get folders_path
    assert_response :success

    # Only 40 folders should be shown on the first page
    assert_equal 40, assigns(:folders).size

    # Fetch the second page
    get folders_path(page: 2)
    assert_response :success

    # The remaining 5 folders should be shown on the second page
    assert_equal 5, assigns(:folders).size

    # Fetch the third page (should be empty)
    get folders_path(page: 3)
    assert_response :success

    # No folders should be shown on the third page
    assert_equal 0, assigns(:folders).size
  end


  test 'should create a subfolder inside a parent folder' do
    # Create a parent folder
    parent_folder = Folder.create!(name: 'Parent Folder', user: @user)

    # Simulate a POST request to create a subfolder
    post folders_path, params: {
      folder: { name: 'Subfolder', parent_id: parent_folder.id }
    }

    # Check if the response is a redirect (folder successfully created)
    assert_response :redirect
    follow_redirect!

    # Ensure the subfolder was created and assigned to the parent
    subfolder = Folder.find_by(name: 'Subfolder')
    assert_not_nil subfolder
    assert_equal parent_folder.id, subfolder.parent_id
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
