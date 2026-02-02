require "./spec_helper"
require "../src/mt/node"
require "../src/mt/grammar"
require "../src/mt/rules"
require "yaml"

describe "QTran Grammar Suite" do
  # Load fixtures
  fixtures = [] of YAML::Any
  Dir.glob("spec/fixtures/grammar/*.yml") do |file|
    content = File.read(file)
    yaml = Array(YAML::Any).from_yaml(content)
    fixtures.concat(yaml)
  end

  # Setup Mocks
  ltp_mock = QTran::MockLtpAdapter.new
  dict_mock = QTran::MockDictAdapter.new

  QTran::LtpClient.adapter = ltp_mock
  QTran::Dictionary.adapter = dict_mock

  fixtures.each do |fixture|
    it "translates: #{fixture["desc"]}" do
      input = fixture["input"].as_s
      expected = fixture["expected"].as_s

      # Setup LTP data
      ltp_data = fixture["ltp"]
      cws = ltp_data["cws"].as_a.map(&.as_s)
      pos = ltp_data["pos"].as_a.map(&.as_s)

      # Create SentenceResult
      res = QTran::LtpClient::SentenceResult.new(cws, pos)
      # res.ner = [] of String # Optional, default nil in struct

      ltp_mock.responses[input] = [res]

      # Setup Dict data
      fixture["dict"].as_h.each do |k, v|
        dict_mock.data[k.as_s] = v.as_s
      end

      # Run logic manualy (mimic qtran.cr) or use CLI run?
      # Let's mimic run logic to verify grammar + output

      # 1. Analyze
      results = QTran::LtpClient.analyze(input)
      sent = results.first

      nodes = [] of QTran::MtNode
      sent.cws.each_with_index do |word, idx|
        pos_str = sent.pos[idx]
        tag = QTran::PosTag.from_ltp(pos_str)
        nodes << QTran::MtNode.new(word, tag)
      end

      # 2. Grammar
      grammar = QTran::Grammar.new
      processed_nodes = grammar.process(nodes)

      # 3. Lookup & Stringify
      output = processed_nodes.map do |root|
        apply_dict_recursive(root)
        root.to_s.strip
      end.join(" ").gsub(/\s+/, " ").gsub(" ,", ",").strip

      output.should eq(expected)
    end
  end
end

def apply_dict_recursive(node : QTran::MtNode)
  if node.leaf?
    if node.val == node.key
      dict_val = QTran::Dictionary.lookup(node.key, node.tag)
      node.val = dict_val if dict_val
    end
  else
    node.children.each { |c| apply_dict_recursive(c) }
  end
end
