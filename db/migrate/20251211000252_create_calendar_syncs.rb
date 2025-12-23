class CreateCalendarSyncs < ActiveRecord::Migration[7.2]
  def change
    create_table :calendar_syncs do |t|
      t.references :appointment, null: false, foreign_key: true
      t.string :service_type, null: false
      t.string :external_event_id
      t.integer :sync_status, default: 0
      t.datetime :last_synced_at
      t.text :error_message

      t.timestamps
    end

    add_index :calendar_syncs, [:appointment_id, :service_type], unique: true
    add_index :calendar_syncs, :sync_status
  end
end
