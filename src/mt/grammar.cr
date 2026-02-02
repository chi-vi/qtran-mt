require "./node"
require "./rules"

module QTran
  class Grammar
    def initialize
    end

    def process(nodes : Array(MtNode)) : Array(MtNode)
      # Recursively apply rules until stable or reduced
      # For simplicity, we apply rules in phases

      current_nodes = nodes

      # 1. Noun Rules (includes Noun Phrasing)
      current_nodes = QTran::NounRules.apply(current_nodes)

      # 2. Verb Rules
      current_nodes = QTran::VerbRules.apply(current_nodes)

      # 3. Preposition Rules
      current_nodes = QTran::PreposRules.apply(current_nodes)

      current_nodes
    end
  end
end
