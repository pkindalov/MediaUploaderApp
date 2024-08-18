# app/controllers/concerns/media_filter.rb
module MediaFilter
  extend ActiveSupport::Concern

  def filter_media_files(media_files, filter)
    case filter
    when 'images'
      media_files.select { |file| file.file.downcase =~ /\.(jpg|jpeg|png|gif)\z/ }
    when 'videos'
      media_files.select { |file| file.file.downcase =~ /\.(mp4|webm|ogg|mov|mkv)\z/ }
    else
      media_files
    end
  end
end
