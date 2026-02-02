require "../node"
require "../pos_tag"

module QTran
  module CompareRules
    extend self

    def apply(nodes : Array(MtNode)) : Array(MtNode)
      new_nodes = [] of MtNode
      i = 0

      while i < nodes.size
        # 1. A + Bi + B + (Adv) + Adj -> A + (Adv) + Adj + Hon + B
        # Pattern: [Bi] [B] [Adv?] [Adj]
        # Note: A is usually previous node, we don't need to capture it if we just re-order the rest to follow A.
        # Structure: ... [Bi] [B] ... -> ... [Adj] [Hon] [B]

        if (bi = nodes[i]) && (bi.key == "比" || bi.key == "比较")
          # Search for Adj
          # Bi + Object + (Adv) + Adj
          # We scan forward carefully.

          # Get B
          idx_b = i + 1
          if (b_node = nodes[idx_b]?) && (b_node.noun? || b_node.pronoun?)
            # Look for Adj
            idx_adj = idx_b + 1
            adv_node : MtNode? = nil

            if (check = nodes[idx_adj]?) && check.adverb?
              adv_node = check
              idx_adj += 1
            end

            if (adj = nodes[idx_adj]?) && adj.adj?
              parent = MtNode.new("", PosTag::Adj)

              bi.val = "hơn"

              # Output: (Adv) + Adj + Hon + B
              # Note: "Also Big" (Cung Lon) -> Cung Lon Hon.
              parent.children << adv_node if adv_node
              parent.children << adj
              parent.children << bi
              parent.children << b_node

              new_nodes << parent
              i = idx_adj + 1
              next
            end
          end
        end

        # 2. A + Meiyou + B + Adj -> A + Khong + Adj + Bang + B
        if (meiyou = nodes[i]) && (meiyou.key == "没有" || meiyou.key == "没")
          # Check if followed by Noun (B) + Adj
          idx_b = i + 1
          if (b_node = nodes[idx_b]?) && (b_node.noun? || b_node.pronoun?)
            idx_adj = idx_b + 1
            if (adj = nodes[idx_adj]?) && adj.adj?
              parent = MtNode.new("", PosTag::Adj)

              meiyou.val = "không"
              bang = MtNode.new("bằng", PosTag::Rel, 0, "bằng")

              # Output: Khong + Adj + Bang + B
              parent.children << meiyou
              parent.children << adj
              parent.children << bang
              parent.children << b_node

              new_nodes << parent
              i = idx_adj + 1
              next
            end
          end
        end

        # 3. Equative/Simile: (Gen/Xiang/Ru) + B + (Yiyang) + Adj -> (Adj) + Nhu/Giong + B
        # Pattern: [Prep] [B] [Yiyang?] [Adj]
        if (prep = nodes[i]) && (prep.key == "跟" || prep.key == "和" || prep.key == "像" || prep.key == "如")
          idx_b = i + 1
          if (b_node = nodes[idx_b]?) && (b_node.noun? || b_node.pronoun?)
            idx_next = idx_b + 1

            # Optional Yiyang
            yiyang : MtNode? = nil
            if (check = nodes[idx_next]?) && (check.key == "一样" || check.key == "一般")
              yiyang = check
              idx_next += 1
            end

            # Adj
            if (adj = nodes[idx_next]?) && adj.adj?
              parent = MtNode.new("", PosTag::Adj)

              # Choose comparator word:
              # If prep is Gen(跟/和) -> need "bang/nhu".
              # If prep is Xiang/Ru -> "nhu".
              # Yiyang often maps to "nhu/bang".

              comparator = MtNode.new("như", PosTag::Compar, 0, "như")

              # If we have Yiyang, use its val? Or just use generic 'như'.
              # "A cao như B" is standard for "A Gen B Yiyang Gao".

              # Output: Adj + Nhu + B
              parent.children << adj
              parent.children << comparator
              parent.children << b_node

              new_nodes << parent
              i = idx_next + 1
              next
            end
          end
        end

        new_nodes << nodes[i]
        i += 1
      end

      new_nodes
    end
  end
end
