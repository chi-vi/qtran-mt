require "http/client"
require "json"

module QTran
  class LtpClient
    BASE_URL = "http://localhost:3003"

    struct SentenceResult
      include JSON::Serializable
      property cws : Array(String)
      property pos : Array(String)
      property ner : Array(String)?

      def initialize(@cws, @pos, @ner = nil)
      end
    end

    # Adapter Interface
    abstract class Adapter
      abstract def analyze(text : String) : Array(SentenceResult)
    end

    class HttpAdapter < Adapter
      def analyze(text : String) : Array(SentenceResult)
        # Ensure text is not empty and has proper line breaks
        return [] of SentenceResult if text.strip.empty?

        response = HTTP::Client.post("#{BASE_URL}/analyze", body: text)

        if response.success?
          Array(SentenceResult).from_json(response.body)
        else
          raise "LTP Server Error: #{response.status_code} - #{response.body}"
        end
      rescue ex
        # For now, if server fails, we might want to return a fallback or re-raise
        # Raising is better so we know something is wrong during dev
        raise ex
      end
    end

    @@adapter : Adapter = HttpAdapter.new

    def self.adapter=(adapter : Adapter)
      @@adapter = adapter
    end

    def self.analyze(text : String) : Array(SentenceResult)
      @@adapter.analyze(text)
    end
  end
end
