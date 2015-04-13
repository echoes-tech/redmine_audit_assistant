class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.string :code
      t.string :name
      t.string :description
      t.belongs_to :audit, index:true
    end
  end
end
