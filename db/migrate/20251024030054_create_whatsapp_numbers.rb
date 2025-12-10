class CreateWhatsappNumbers < ActiveRecord::Migration[7.2]
  def change
    create_table :whatsapp_numbers do |t|
      t.references :user, null: false, foreign_key: true
      t.string :phone_number, null: false
      t.string :webhook_url
      t.boolean :is_active, default: true

      t.timestamps
    end
    
    add_index :whatsapp_numbers, :phone_number, unique: true
  end
end
