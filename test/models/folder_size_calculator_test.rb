require 'test_helper'

class FolderSizeCalculatorTest < ActiveSupport::TestCase
  def setup
    # Създаване на уникален потребител и папка
    unique_email = "user_#{SecureRandom.hex(5)}@example.com"
    @user = User.create!(email: unique_email, password: 'password')
    @folder = Folder.create!(name: 'MyFolder', user: @user)
  end

  test 'should calculate correct total size' do
    @media_file1 = MediaFile.create!(file: 'file1.txt', folder: @folder)
    create_test_file(@folder, 'file1.txt', 100.kilobytes)

    total_size = calculate_total_size(@folder)
    assert_equal '100 KB', total_size
  end

  test 'should calculate correct total size with multiple files' do
    @media_file1 = MediaFile.create!(file: 'file1.txt', folder: @folder)
    @media_file2 = MediaFile.create!(file: 'file2.txt', folder: @folder)
    create_test_file(@folder, 'file1.txt', 100.kilobytes)
    create_test_file(@folder, 'file2.txt', 200.kilobytes)

    total_size = calculate_total_size(@folder)
    assert_equal '300 KB', total_size
  end

  test 'should calculate correct total size with empty folder' do
    # Папката няма файлове, затова размерът трябва да е 0 байта
    total_size = calculate_total_size(@folder)
    assert_equal '0 Bytes', total_size
  end

  test 'should calculate correct total size with many small files' do
    # Създаваме 100 малки файла по 1 KB
    100.times do |i|
      file_name = "file#{i + 1}.txt"
      MediaFile.create!(file: file_name, folder: @folder)
      create_test_file(@folder, file_name, 1.kilobyte)
    end

    total_size = calculate_total_size(@folder)
    assert_equal '100 KB', total_size
  end

  test 'should calculate correct total size with empty file' do
    @media_file1 = MediaFile.create!(file: 'file1.txt', folder: @folder)
    @media_file2 = MediaFile.create!(file: 'file2.txt', folder: @folder)
    create_test_file(@folder, 'file1.txt', 100.kilobytes)
    create_test_file(@folder, 'file2.txt', 0)

    total_size = calculate_total_size(@folder)
    assert_equal '100 KB', total_size
  end

  test 'should calculate correct total size with varying file sizes' do
    @media_file1 = MediaFile.create!(file: 'file1.txt', folder: @folder)
    @media_file2 = MediaFile.create!(file: 'file2.txt', folder: @folder)
    @media_file3 = MediaFile.create!(file: 'file3.txt', folder: @folder)
    @media_file4 = MediaFile.create!(file: 'file4.txt', folder: @folder)

    create_test_file(@folder, 'file1.txt', 100.kilobytes)
    create_test_file(@folder, 'file2.txt', 50.kilobytes)
    create_test_file(@folder, 'file3.txt', 150.kilobytes)
    create_test_file(@folder, 'file4.txt', 200.kilobytes)

    total_size = calculate_total_size(@folder)
    assert_equal '500 KB', total_size
  end


  test 'should update folder size after file is updated' do
    # Актуализиране на съществуващия файл с нов размер 200 KB
    create_test_file(@folder, 'file1.txt', 200.kilobytes)

    # Презареждане на медийния файл или създаване на нов
    @media_file = MediaFile.find_or_initialize_by(file: 'file1.txt', folder: @folder)
    @media_file.save! # Запазване на актуализацията, ако е необходимо

    # Изчисляване на размера след актуализацията
    total_size = calculate_total_size(@folder)
    assert_equal '200 KB', total_size
  end


  private

  def create_test_file(folder, filename, size)
    file_path = "#{Rails.root}/tmp/tests/#{folder.user.email}/#{folder.name}/#{filename}"
    FileUtils.mkdir_p(File.dirname(file_path))
    File.open(file_path, 'wb') { |f| f.write('0' * size) }
  end

  def calculate_total_size(folder)
    total_size = folder.media_files.sum { |file| File.size(file_path(file)) }
    ActiveSupport::NumberHelper.number_to_human_size(total_size)
  end

  def file_path(file)
    "#{Rails.root}/tmp/tests/#{file.folder.user.email}/#{file.folder.name}/#{file.file}"
  end
end
