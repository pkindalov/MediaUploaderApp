# frozen_string_literal: true

class DownloadsController < ApplicationController
  before_action :authenticate_user!

  def serve
    file_path = params[:file_path]

    if File.exist?(file_path)
      send_file file_path,
                type: mime_type(file_path),
                disposition: 'inline',
                stream: true,
                buffer_size: 4096
    else
      render plain: 'Файлът не е намерен', status: :not_found
    end
  end

  private

  def mime_type(file_path)
    case File.extname(file_path).downcase
    when '.jpg', '.jpeg' then 'image/jpeg'
    when '.png' then 'image/png'
    when '.gif' then 'image/gif'
    when '.mp4' then 'video/mp4'
    when '.webm' then 'video/webm'
    when '.ogg' then 'video/ogg'
    when '.mov' then 'video/quicktime'
    else 'application/octet-stream'
    end
  end

end
