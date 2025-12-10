class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name
      t.string :google_id, null: false
      t.text :access_token
      t.text :refresh_token
      t.datetime :expires_at
      t.string :provider, default: 'google'
      t.string :plan, default: 'basic'
      t.integer :whatsapp_numbers_limit, default: 1

      t.timestamps
    end
    
    add_index :users, :email, unique: true
    add_index :users, :google_id, unique: true
  end
end
