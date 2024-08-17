# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :set_user, only: [:show]

  def show
    @folders = @user.folders.paginate(page: params[:folders_page], per_page: 20).order('created_at DESC')
    @media_files = @user.media_files.paginate(page: params[:files_page], per_page: 50).order('created_at DESC')
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Потребителят не беше намерен.'
  end
end
