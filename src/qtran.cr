require "./client/ltp"
require "./mt/node"
require "./mt/grammar"
require "./data/dictionary"

module QTran
  class CLI
    def run
      input = ARGV.join(" ")
      if input.empty?
        puts "Usage: qtran <text>"
        exit 1
      end

      # 1. Analyze
      begin
        results = LtpClient.analyze(input)
      rescue ex
        puts "Error calling LTP server: #{ex.message}"
        exit 1
      end

      # 2. Process each sentence
      results.each do |sent|
        nodes = [] of MtNode
        sent.cws.each_with_index do |word, idx|
          pos_str = sent.pos[idx]? || "n" # Default to noun
          tag = PosTag.from_ltp(pos_str)
          nodes << MtNode.new(word, tag, idx)
        end

        # 3. Apply Grammar
        grammar = Grammar.new
        processed_nodes = grammar.process(nodes)

        # 4. Dictionary Lookup & Output
        output = processed_nodes.map do |node|
          if node.val == node.key
            dict_val = Dictionary.lookup(node.key, node.tag)
            node.val = dict_val || "⦰⦰"
          end
          node.val
        end.join(" ")

        puts output
      end
    end
  end
end

QTran::CLI.new.run
