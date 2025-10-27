class CreateCalendarConfigs < ActiveRecord::Migration[7.2]
  def change
    create_table :calendar_configs do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :day_of_week
      t.time :start_time
      t.time :end_time
      t.boolean :is_active
      t.text :notes

      t.timestamps
    end
  end
end
