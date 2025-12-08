class CreateSchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :schedules do |t|
      t.string :title, null: false
      t.text :description
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.string :location
      t.boolean :all_day, default: false
      t.references :calendar, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :schedules, :start_time
    add_index :schedules, :end_time
    add_index :schedules, [:calendar_id, :start_time]
  end
end
