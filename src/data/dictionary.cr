require "sqlite3"
require "../mt/pos_tag"

module QTran
  class Dictionary
    DB_PATH = "/srv/chivi/mt_db/v1_defns.db3"

    # We will query the DB directly for now.
    # In the future, we can load into memory like the old implementation.

    abstract class Adapter
      abstract def lookup(word : String, tag : PosTag) : String?
      abstract def close
    end

    class SqliteAdapter < Adapter
      @db : DB::Database

      def initialize(@db_path : String)
        @db = DB.open("sqlite3:#{@db_path}")
      end

      def lookup(word : String, tag : PosTag) : String?
        sql = "SELECT vstr FROM defns WHERE d_id = -1 AND zstr = ? LIMIT 1"
        @db.query_one?(sql, word, as: String)
      rescue
        nil
      end

      def close
        @db.close
      end
    end

    @@adapter : Adapter?

    def self.adapter=(adapter : Adapter)
      @@adapter = adapter
    end

    def self.ensure_adapter
      @@adapter ||= SqliteAdapter.new(DB_PATH)
    end

    def self.lookup(word : String, tag : PosTag) : String?
      ensure_adapter.lookup(word, tag)
    end

    def self.close
      @@adapter.try &.close
      @@adapter = nil
    end
  end
end
