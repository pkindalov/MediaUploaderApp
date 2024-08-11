class DownloadsController < ApplicationController
  before_action :authenticate_user!
  def serve
    # Получаване на пътя до файла от параметрите
    file_path = params[:file_path]

    # Проверка дали файлът съществува
    if File.exist?(file_path)
      # Изпращане на файла към клиента
      send_file file_path, disposition: 'inline'
    else
      # Показване на съобщение за грешка, ако файлът не съществува
      render plain: 'Файлът не е намерен', status: :not_found
    end
  end
end
