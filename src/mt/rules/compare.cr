require "../node"
require "../pos_tag"

module QTran
  module CompareRules
    extend self

    def apply(node : MtNode) : MtNode
      if node.tag.prepos? && node.key == "比" && node.val != "hơn"
        fold_bi(node)
      else
        node
      end
    end

    def fold_bi(bi_node : MtNode) : MtNode
      # Pattern: [A] [Bi] [B] [Adj]
      # VN: [A] [Adj] (hơn) [B]

      # 1. Identify A (Prev)
      subj_a = bi_node.prev
      # 2. Identify B (Succ)
      subj_b = bi_node.succ

      return bi_node unless subj_b

      # 3. Identify Adj (After B)
      adj = subj_b.succ

      if adj && (adj.adj? || adj.verb?) # Sometimes verb like "run fast"
        # Move [Bi] [B] to after [Adj]

        # Detach Bi
        bi_node.remove!

        # Detach B
        subj_b.remove!

        # Insert Bi after Adj
        adj.insert_after(bi_node)

        # Insert B after Bi
        bi_node.insert_after(subj_b)

        bi_node.val = "hơn"

        return adj # Resume from current position (Adj is now earlier in stream effectively, but our loop pointer needs to be handled)
        # Actually we return `adj` so the loop continues from `adj`?
        # If we return `adj`, the loop moves to `adj.succ` which is `bi`.
        # That seems correct.
      end

      bi_node.val = "so với" # Fallback if no Adj found
      bi_node
    end
  end
end
