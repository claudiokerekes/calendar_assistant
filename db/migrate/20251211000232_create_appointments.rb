class CreateAppointments < ActiveRecord::Migration[7.2]
  def change
    create_table :appointments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.datetime :start_datetime, null: false
      t.datetime :end_datetime, null: false
      t.integer :status, default: 0
      t.string :location
      t.string :whatsapp_client
      t.json :external_calendar_ids, default: {}

      t.timestamps
    end

    add_index :appointments, [:user_id, :start_datetime]
    add_index :appointments, [:user_id, :whatsapp_client]
    add_index :appointments, :status
  end
end
