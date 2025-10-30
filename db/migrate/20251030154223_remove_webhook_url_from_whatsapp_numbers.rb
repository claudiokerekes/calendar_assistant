class RemoveWebhookUrlFromWhatsappNumbers < ActiveRecord::Migration[7.2]
  def change
    remove_column :whatsapp_numbers, :webhook_url, :string
  end
end
