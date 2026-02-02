require "yaml"
require "json"
require "sqlite3"
require "./src/client/ltp"
require "./src/data/dictionary"
require "./src/mt/pos_tag"
require "./src/mt/grammar"
require "./src/mt/node"

output_passing = "spec/fixtures/grammar/legacy_passing.yml"
output_failing = "spec/fixtures/grammar/legacy_failing.yml"
samples_dir = "spec/samples"

# Initialize Adapters
# Use real HTTP adapter (default)
# Use real Sqlite Dictionary
# Ensure DB exists? We assume so.
QTran::Dictionary.ensure_adapter

fixtures_passing = [] of YAML::Any
fixtures_failing = [] of YAML::Any
seen_inputs = Set(String).new

# Limit samples to avoid overwhelming
SAMPLE_LIMIT = 50
count = 0
count_pass = 0
count_fail = 0

Dir.glob("#{samples_dir}/**/*.tsv").each do |file|
  basename = File.basename(file, ".tsv")
  puts "Processing #{file}..."

  File.each_line(file) do |line|
    line = line.strip
    next if line.empty?
    next if line.starts_with?("#")

    parts = line.split("\t")
    if parts.size >= 2
      input = parts[0].strip
      expected = parts[1].strip

      next if input.empty? || expected.empty?
      next if seen_inputs.includes?(input)
      seen_inputs.add(input)

      begin
        # 1. Analyze with LTP
        results = QTran::LtpClient.analyze(input)
        next if results.empty?
        sent = results.first # multiline? just take first for now.

        # 2. Build Nodes & Dict
        nodes = [] of QTran::MtNode
        dict_data = Hash(String, String).new

        sent.cws.each_with_index do |word, idx|
          pos_str = sent.pos[idx]
          tag = QTran::PosTag.from_ltp(pos_str)
          nodes << QTran::MtNode.new(word, tag, idx)

          if val = QTran::Dictionary.lookup(word, tag)
            dict_data[word] = val
          else
            # dict_data[word] = word
          end
        end

        # 3. Run Grammar (to check pass/fail)
        grammar = QTran::Grammar.new
        processed_nodes = grammar.process(nodes.dup) # dup to avoid mutation issues if reusing

        # 4. Output generation
        # We need to simulate the apply_dict logic?
        # Or just check structure?
        # The spec runner mimics `apply_dict_recursive`.
        # Let's do simple dict application here for verification.

        calc_output = processed_nodes.map do |root|
          # Recursive dict lookup helper?
          apply_dict(root, dict_data)
          root.to_s.strip
        end.join(" ").gsub(/\s+/, " ").strip

        # Normalize for comparison?
        # expected

        normalized_calc = calc_output.downcase.gsub(/[.,?]/, "").strip
        normalized_exp = expected.downcase.gsub(/[.,?]/, "").strip

        passed = (normalized_calc == normalized_exp)

        # Construct Fixture
        # Use YAML types explicitly

        ltp_hash = Hash(YAML::Any, YAML::Any).new
        ltp_hash[YAML::Any.new("cws")] = YAML::Any.new(sent.cws.map { |x| YAML::Any.new(x) })
        ltp_hash[YAML::Any.new("pos")] = YAML::Any.new(sent.pos.map { |x| YAML::Any.new(x) })

        dict_yaml = Hash(YAML::Any, YAML::Any).new
        dict_data.each do |k, v|
          dict_yaml[YAML::Any.new(k)] = YAML::Any.new(v)
        end

        fixture = Hash(YAML::Any, YAML::Any).new
        fixture[YAML::Any.new("id")] = YAML::Any.new("legacy_#{basename}_#{count}")
        fixture[YAML::Any.new("desc")] = YAML::Any.new("Legacy: #{input}")
        fixture[YAML::Any.new("input")] = YAML::Any.new(input)
        fixture[YAML::Any.new("ltp")] = YAML::Any.new(ltp_hash)
        fixture[YAML::Any.new("dict")] = YAML::Any.new(dict_yaml)
        fixture[YAML::Any.new("expected")] = YAML::Any.new(expected)

        if passed
          # Update expected to match actual output strictly for the test suite
          fixture[YAML::Any.new("expected")] = YAML::Any.new(calc_output)
          fixtures_passing << YAML::Any.new(fixture)
          count_pass += 1
          print "."
        else
          # fixture[YAML::Any.new("actual")] = YAML::Any.new(calc_output) # Optional debug
          fixtures_failing << YAML::Any.new(fixture)
          count_fail += 1
          print "x"
        end

        count += 1
      rescue ex
        puts "Error processing '#{input}': #{ex.message}"
      end
    end
  end
end

def apply_dict(node, dict)
  if node.children.empty?
    # Only lookup if val hasn't been modified by grammar (matches spec runner logic)
    if node.val == node.key
      if val = dict[node.key]?
        node.val = val
      end
    end
  else
    node.children.each { |c| apply_dict(c, dict) }
  end
end

puts "\nWriting #{fixtures_passing.size} PASSING fixtures to #{output_passing}..."
File.write(output_passing, fixtures_passing.to_yaml)

puts "Writing #{fixtures_failing.size} FAILING fixtures to #{output_failing}..."
File.write(output_failing, fixtures_failing.to_yaml)
puts "Done."
