# frozen_string_literal: true

require 'test_helper'

class MediaFilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one) # Увери се, че имаш фикстура за потребител
    @folder = folders(:one) # Увери се, че имаш фикстура за папка
    @media_file = media_files(:one) # Увери се, че имаш фикстура за медиа файл
    sign_in @user
  end

  test 'should get index' do
    get folder_media_files_url(@folder)
    assert_response :success
    assert_not_nil assigns(:media_files)
    assert_not_nil assigns(:exif_data)
  end

  test 'should get list_all_files' do
    get list_files_url
    assert_response :success
    assert_not_nil assigns(:files)
  end

  test 'should get new' do
    get new_folder_media_file_url(@folder)
    assert_response :success
  end

  test 'should create media_file' do
    file = fixture_file_upload('test/fixtures/files/test_image.png', 'image/png')

    assert_difference('MediaFile.count', 1) do
      post folder_media_files_url(@folder), params: {
        media_file: { files: [file] }
      }
    end

    assert_redirected_to folder_media_files_path(@folder)
  end

  test 'should not create media_file when exceeding max upload limit' do
    file = fixture_file_upload('test/fixtures/files/test_image.png', 'image/png')

    ENV['MAX_FILES_UPLOAD_AT_ONCE'] = '1'

    assert_no_difference('MediaFile.count') do
      post folder_media_files_url(@folder), params: {
        media_file: { files: [file, file] }
      }
    end

    assert_redirected_to new_folder_media_file_path(@folder)
  end

  test 'should get edit' do
    get edit_folder_media_file_url(@folder, @media_file)
    assert_response :success
  end

  test 'should update media_file' do
    patch folder_media_file_url(@folder, @media_file), params: {
      media_file: { file: 'updated_name.jpg' }
    }
    assert_redirected_to folder_media_files_path(@folder)
  end

  test 'should destroy media_file' do
    assert_difference('MediaFile.count', -1) do
      delete folder_media_file_url(@folder, @media_file)
    end

    assert_redirected_to folder_media_files_path(@folder)
  end

  test 'should not allow unauthorized user to edit or destroy media_file' do
    other_user = users(:two) # Увери се, че имаш фикстура за втори потребител
    sign_in other_user

    get edit_folder_media_file_url(@folder, @media_file)
    assert_redirected_to root_path

    delete folder_media_file_url(@folder, @media_file)
    assert_redirected_to root_path
  end
end
