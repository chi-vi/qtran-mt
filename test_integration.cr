require "./src/client/ltp"
require "./src/mt/node"
require "./src/mt/grammar"
require "./src/data/dictionary"
require "./src/mt/rules"

# Mock Dictionary for consistent testing
module QTran
  class Dictionary
    @@mock_data = {
      "我"   => "tôi",
      "吃"   => "ăn",
      "苹果"  => "táo",
      "红"   => "đỏ",
      "花"   => "hoa",
      "的"   => "của",
      "书"   => "sách",
      "汉字"  => "Hán tự",
      "字典"  => "từ điển",
      "在"   => "ở",
      "家"   => "nhà",
      "里"   => "trong",
      "把"   => "đem",
      "了"   => "rồi",
      "被"   => "bị",
      "比"   => "so với", # rule changes to 'hơn' if applicable
      "你"   => "bạn",
      "大"   => "lớn",
      "红花"  => "hoa đỏ",
      "大苹果" => "táo to",
      "家里"  => "trong nhà",
      "上"   => "trên",
      "下"   => "dưới",
      "明天"  => "ngày mai",
      "去"   => "đi",
      "学校"  => "trường",
      "商店"  => "tiệm",
      "买"   => "mua",
      "东西"  => "đồ",
      "他"   => "anh ấy",
      "给"   => "cho",
      "一"   => "một",
      "本"   => "quyển",
      "看不见" => "nhìn không thấy",
      "跑"   => "chạy",
      "得"   => "được", # or particle
      "快"   => "nhanh",
      "是"   => "là",
      "学生"  => "học sinh",
      "非常"  => "rất",
      "好"   => "tốt",
      "坐"   => "ngồi",
      "椅子"  => "ghế",
      "喜欢"  => "thích",
      "看"   => "xem",
      "电影"  => "phim",
    } of String => String

    def self.lookup(word : String, tag : PosTag) : String?
      @@mock_data[word]?
    end
  end
end

def run_test(input : String, expected_part : String)
  puts "\nInput: #{input}"

  begin
    results = QTran::LtpClient.analyze(input)
  rescue ex
    puts "Error: #{ex.message}"
    return
  end

  if results.empty?
    puts "No results from LTP."
    return
  end

  sent = results.first
  nodes = [] of QTran::MtNode
  sent.cws.each_with_index do |word, idx|
    pos_str = sent.pos[idx]? || "n"
    tag = QTran::PosTag.from_ltp(pos_str)
    nodes << QTran::MtNode.new(word, tag)
  end

  print "Tags: "
  puts nodes.map { |n| "#{n.key}(#{n.tag})" }.join(", ")

  # Apply Grammar
  grammar = QTran::Grammar.new
  processed_nodes = grammar.process(nodes)

  # Dictionary Lookup
  output = processed_nodes.map do |node|
    if node.val == node.key
      dict_val = QTran::Dictionary.lookup(node.key, node.tag)
      node.val = dict_val || "⦰#{node.key}⦰"
    end
    node.val
  end.join(" ")

  puts "Output: #{output}"

  if output.downcase.includes?(expected_part.downcase)
    puts "✅ PASS (Matches '#{expected_part}')"
  else
    puts "❌ FAIL (Expected '#{expected_part}')"
  end
end

puts "=== Running Integration Tests with Live LTP Server ==="

# 1. Simple SVO
run_test("我吃苹果", "tôi ăn táo")

# 2. Adj + Noun
run_test("红花", "hoa đỏ")

# 3. Noun + de + Noun
run_test("我的书", "sách của tôi")

# 4. Noun + Noun
run_test("汉字字典", "từ điển Hán tự")

# 5. Zai + Loc + V (Note: LTP might split 'zai jia li' differently)
# "wo zai jia li chi fan" -> "zai jia li" is PP
run_test("我在家里吃苹果", "ăn táo ở trong nhà")
# Expect: Toi an tao o trong nha (Order: V + PP)

# 6. Ba structure
run_test("我把苹果吃了", "tôi ăn táo rồi")

# 7. Bei structure
run_test("苹果被我吃了", "táo bị tôi ăn rồi")

# 8. Comparison
run_test("我比你大", "tôi lớn hơn bạn")

# 9. Time + S + V
run_test("明天我去学校", "ngày mai tôi đi trường")

# 10. Serial verbs
run_test("我去商店买东西", "tôi đi tiệm mua đồ")

# 11. Copula 'Shi'
run_test("我是学生", "tôi là học sinh")

# 12. Adverb + Adj
run_test("非常好", "rất tốt")

# 13. Location Phrase (Zai + N + Shang)
run_test("坐在椅子上", "ngồi ở trên ghế")
# "Zuo zai yizi shang" -> "Ngoi o tren ghe" (Zai moved after Zuo? Or Zuo Zai treated as V + Result?)
# Rule Zai+Loc+V covers [Zai Loc] [V]. This is [V] [Zai Loc].
# Normal order for VN is [V] [at] [Loc]. Chinese is often [Zai Loc] [V] or [V] [Zai Loc].
# If Chinese is [V] [Zai Loc], VN is same.
# We need to ensure 'zai' translates to 'ở'.

# 14. Double verb/preference
run_test("我喜欢看电影", "tôi thích xem phim")
