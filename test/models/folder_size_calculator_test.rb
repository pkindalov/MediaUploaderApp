require 'test_helper'

class FolderSizeCalculatorTest < ActiveSupport::TestCase
  def setup
    # Създаване на уникален потребител и папка
    unique_email = "user_#{SecureRandom.hex(5)}@example.com"
    @user = User.create!(email: unique_email, password: 'password')
    @folder = Folder.create!(name: 'MyFolder', user: @user)

    # Създаване на медиен файл в папката
    @media_file = MediaFile.create!(file: 'file1.txt', folder: @folder)

    # Създаване на фиктивен файл с размер 100 KB
    create_test_file(@folder, 'file1.txt', 100.kilobytes)
  end

  test 'should calculate correct total size' do
    total_size = calculate_total_size(@folder)
    assert_equal '100 KB', total_size
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
