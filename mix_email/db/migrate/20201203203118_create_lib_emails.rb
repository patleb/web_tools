class CreateLibEmails < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_emails do |t|
      t.string  :mailer,  null: false
      t.boolean :sent,    null: false, default: false
      t.string  :from,    null: false
      t.string  :to,      null: false
      t.string  :cc
      t.string  :bcc
      t.string  :subject, null: false

      t.timestamps
    end
  end
end
