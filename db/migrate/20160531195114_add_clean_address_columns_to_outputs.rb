class AddCleanAddressColumnsToOutputs < ActiveRecord::Migration
  def change
    add_column :outputs, :clean_street, :text
    add_column :outputs, :clean_citystatezip, :text
  end
end
