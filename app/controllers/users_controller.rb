# app/controllers/users_controller.rb
class UsersController < ApplicationController
  include FileSorting
  before_action :set_user, only: [:show]

  def show
    folders = @user.folders.order('created_at DESC')
    @folders = WillPaginate::Collection.create(params[:folders_page] || 1, 20, folders.size) do |pager|
      pager.replace(folders[pager.offset, pager.per_page].to_a)
    end

    media_files = @user.media_files.order('created_at DESC')
    sorted_files = sort_files_by_availability(media_files)
    sorted_files ||= []

    @media_files = WillPaginate::Collection.create(params[:files_page] || 1, 50, sorted_files.size) do |pager|
      pager.replace(sorted_files[pager.offset, pager.per_page].to_a)
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Потребителят не беше намерен.'
  end
end
