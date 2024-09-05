# frozen_string_literal: true

require 'test_helper'

class FoldersControllerTest < ActionDispatch::IntegrationTest
  setup do
    # @user = User.create!(email: 'testuser@example.com', password: 'password')
    @user = User.find_by(email: 'user@example.com') || User.create!(email: 'user@example.com', password: 'password')
    @root_folder_path = Rails.configuration.user_files_path
    @user_main_folder_path = File.join(@root_folder_path, @user.email)

    # Creating user's main directory
    FileUtils.mkdir_p(@user_main_folder_path)

    # puts "User details: #{@user.inspect}"
    # puts "User main directory: #{@user_main_folder_path}"
    # puts Rails.configuration.user_files_path
  end

  # test 'experiment' do
  #   assert true
  # end

  def teardown
    FileUtils.rm_rf(@user_main_folder_path) if Dir.exist?(@user_main_folder_path)
  end

  test 'create one folder and one subfolder and then move the subfolder on the level of the folder' do
    # Now, create a folder in the database and on the flash drive
    @main_test_folder = 'Documents'
    @user_documents_folder = @user.folders.create!(name: @main_test_folder)
    assert @user_documents_folder.persisted?

    if @user_documents_folder.persisted?
      @main_test_folder_root = File.join(@user_main_folder_path, @main_test_folder)

      FileUtils.mkdir_p(@main_test_folder_root)
      assert Dir.exist?(@main_test_folder_root)
      if Dir.exist?(@main_test_folder_root)
        # Creating a subfolder
        @sub_test_folder = 'Documents_Subfolder'
        @sub_test_folder_root = File.join(@main_test_folder_root, @sub_test_folder)
        # must insert it into db before create it on the outer source - hard/flash drive
        @user_doc_subfolder = @user.folders.create!(name: @sub_test_folder, parent_id: @user_documents_folder.id)
        # to check if it is inserted correctly into db and if everything is correct then to
        # create it on the outer source (outer hard drive, flash drive etc...).
        assert @user_doc_subfolder.persisted?
        if @user_doc_subfolder.persisted?
          FileUtils.mkdir_p(@sub_test_folder_root)
          assert Dir.exist?(@sub_test_folder_root)
        else
          raise "Error creating subfolder #{@sub_test_folder} in database"
        end

        assert Dir.exist?(@sub_test_folder_root)
        if Dir.exist?(@sub_test_folder_root)
          # updating parent_id of the moved folder
          @user_doc_subfolder.update!(parent_id: nil)
          assert_nil @user_doc_subfolder.parent_id,'Expected parent_id to be nil after update'

          # to move folder to the main test folder - @main_test_folder('Documents')
          FileUtils.mv(@sub_test_folder_root, File.join(@user_main_folder_path, @sub_test_folder))
          assert Dir.exist?(File.join(@user_main_folder_path, @sub_test_folder))
        else
          raise "Subdirectory #{@sub_test_folder} didn't create successful"
        end

      else
        raise 'Error creating parent folder'
      end

    else
      raise 'Error: Folder could not be created in the database.'
    end

  end

  # test 'create one folder and several subfolders and then move the last subfolder on the level of the main folder' do
  #
  # end
  #
  # test 'create one folder and several subfolders and then move the last subfolder one level up' do
  #
  # end
  #
  # test 'create one folder and several subfolders and then move the not last subfolder one level up' do
  #
  # end
  #
  # test 'create one folder and several subfolders and then move the not last subfolder one level of the main folder' do
  #
  # end

end
