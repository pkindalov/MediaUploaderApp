class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # Добавяне на хелпърите на Devise
  helper_method :user_signed_in?, :current_user
end
