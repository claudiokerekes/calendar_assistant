class CreateConversations < ActiveRecord::Migration[7.2]
  def change
    create_table :conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :whatsapp_client, null: false

      t.timestamps
    end
    
    add_index :conversations, [:user_id, :whatsapp_client], unique: true
  end
end
