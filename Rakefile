require "active_record"

namespace :db do

  desc "Migrate the database"
  task :migrate do
    ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"])
    ActiveRecord::Migrator.migrate("db/migrate/")
    Rake::Task["db:schema"].invoke
    puts "Database migrated."
  end

  desc "Reset the database"
  task :reset => [:drop, :create, :migrate]

  desc 'Create a db/schema.rb file that is portable against any DB supported by AR'
  task :schema do
    ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"])
    require 'active_record/schema_dumper'
    filename = "db/schema.rb"
    File.open(filename, "w:utf-8") do |file|
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
    end
  end

  desc "Rollback the database"
  task :rollback do
    ActiveRecord::Base.establish_connection(db_config)
    ActiveRecord::MigrationContext.new("db/migrate/").rollback
    Rake::Task["db:schema"].invoke
    puts "Last migration has been reverted."
  end

end

namespace :g do
  desc "Generate migration"
  task :migration do
    name = ARGV[1] || raise("Specify name: rake g:migration your_migration")
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    path = File.expand_path("../db/migrate/#{timestamp}_#{name}.rb", __FILE__)
    migration_class = name.split("_").map(&:capitalize).join

    File.open(path, 'w') do |file|
      file.write <<-EOF
class #{migration_class} < ActiveRecord::Migration
  def self.up
  end
  def self.down
  end
end
      EOF
    end

    puts "Migration #{path} created"
    abort # needed stop other tasks
  end
end