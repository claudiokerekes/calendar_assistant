class CreateMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.text :message_content, null: false
      t.integer :user_type, null: false
      t.integer :prompt_tokens
      t.integer :completion_tokens

      t.timestamps
    end
    
    add_index :messages, :created_at
  end
end
