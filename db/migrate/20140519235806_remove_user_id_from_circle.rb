class RemoveUserIdFromCircle < ActiveRecord::Migration
  def change
    remove_column("circles", "user_id")
  end
end
