require "../src/client/ltp"
require "../src/data/dictionary"
require "json"
require "spec"

module QTran
  class MockLtpAdapter < LtpClient::Adapter
    property responses = {} of String => Array(LtpClient::SentenceResult)

    def analyze(text : String) : Array(LtpClient::SentenceResult)
      # Normalize spaces?
      # For now, exact match or simple lookup
      if res = @responses[text]?
        res
      else
        # Return empty or raise?
        # raise "No mock LTP response for: #{text}"
        [] of LtpClient::SentenceResult
      end
    end
  end

  class MockDictAdapter < Dictionary::Adapter
    property data = {} of String => String

    def lookup(word : String, tag : PosTag) : String?
      @data[word]?
    end

    def close
    end
  end
end
