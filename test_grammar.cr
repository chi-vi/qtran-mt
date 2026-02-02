require "./src/mt/grammar"
require "./src/mt/node"
require "./src/mt/pos_tag"

include QTran

def print_nodes(head)
  nodes = [] of String
  curr = head
  while curr
    nodes << "#{curr.key}(#{curr.tag})"
    curr = curr.succ
  end
  puts nodes.join(" -> ")
end

puts "--- Test 1: Adj + Noun ---"
# Red(Adj) Flower(Noun) -> Flower Red
n1 = MtNode.new("红", PosTag::Adj)
n2 = MtNode.new("花", PosTag::Noun)
n1.succ = n2
n2.prev = n1

print "Before: "
print_nodes(n1)

head = Rules.apply_all(n1)

print "After:  "
print_nodes(head)

puts "\n--- Test 2: Noun + de + Noun ---"
# I(N) de Book(N) -> Book of I
n1 = MtNode.new("我", PosTag::Pronoun)
n2 = MtNode.new("的", PosTag::PartDe)
n3 = MtNode.new("书", PosTag::Noun)

n1.succ = n2; n2.prev = n1
n2.succ = n3; n3.prev = n2

print "Before: "
print_nodes(n1)

head = Rules.apply_all(n1)

print "After:  "
print_nodes(head)

puts "\n--- Test 3: Noun + Noun ---"
# Kanji(N) Dictionary(N) -> Dictionary Kanji
n1 = MtNode.new("汉字", PosTag::Noun)
n2 = MtNode.new("字典", PosTag::Noun)

n1.succ = n2; n2.prev = n1

print "Before: "
print_nodes(n1)

head = Rules.apply_all(n1)

print "After:  "
print_nodes(head)

puts "\n--- Test 4: Zai + Loc + Verb ---"
# I(N) Zai(Prep) Home(N) Eat(V) -> I Eat At Home
n1 = MtNode.new("我", PosTag::Pronoun)
n2 = MtNode.new("在", PosTag::Prepos)
n3 = MtNode.new("家", PosTag::NPlace) # Or Noun
n4 = MtNode.new("吃", PosTag::Verb)

n1.succ = n2; n2.prev = n1
n2.succ = n3; n3.prev = n2
n3.succ = n4; n4.prev = n3

print "Before: "
print_nodes(n1)
head = Rules.apply_all(n1)
print "After:  "
print_nodes(head)

puts "\n--- Test 5: Ba + Obj + Verb ---"
# I(N) Ba(Prep) Apple(N) Eat(V) -> I Eat Apple
n1 = MtNode.new("我", PosTag::Pronoun)
n2 = MtNode.new("把", PosTag::Prepos)
n3 = MtNode.new("苹果", PosTag::Noun)
n4 = MtNode.new("吃", PosTag::Verb)

n1.succ = n2; n2.prev = n1
n2.succ = n3; n3.prev = n2
n3.succ = n4; n4.prev = n3

print "Before: "
print_nodes(n1)
head = Rules.apply_all(n1)
print "After:  "
print_nodes(head)

puts "\n--- Test 6: A + Bi + B + Adj ---"
# I(N) Bi(P) You(N) Big(Adj) -> I Big Hon You
n1 = MtNode.new("我", PosTag::Pronoun)
n2 = MtNode.new("比", PosTag::Prepos) # Using Prepos for Bi
n3 = MtNode.new("你", PosTag::Pronoun)
n4 = MtNode.new("大", PosTag::Adj)

n1.succ = n2; n2.prev = n1
n2.succ = n3; n3.prev = n2
n3.succ = n4; n4.prev = n3

print "Before: "
print_nodes(n1)
head = Rules.apply_all(n1)
print "After:  "
print_nodes(head)
