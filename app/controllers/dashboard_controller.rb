class DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @whatsapp_numbers = current_user.whatsapp_numbers.active
    @can_add_number = current_user.can_add_whatsapp_number?
  end
  
  def whatsapp_numbers
    @whatsapp_numbers = current_user.whatsapp_numbers
    @new_whatsapp_number = current_user.whatsapp_numbers.build
  end
end