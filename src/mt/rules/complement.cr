require "../node"
require "../pos_tag"

module QTran
  module ComplementRules
    extend self

    def apply(nodes : Array(MtNode)) : Array(MtNode)
      new_nodes = [] of MtNode
      i = 0

      while i < nodes.size
        # 1. Degree / Potential Complement: [Verb/Adj] [De/Bu] [Complement]
        # Match: [V/A] [De/Bu] [V/A/Adv]
        if (head = nodes[i]) && (head.verb? || head.adj?)
          if (part = nodes[i + 1]?) && (part.key == "得" || part.key == "不")
            if (compl = nodes[i + 2]?)
              # Check if Compl is valid (Adj, Verb, Adv)
              if compl.adj? || compl.verb? || compl.adverb? || compl.tag == PosTag::VCo
                parent = MtNode.new("", head.tag)

                # Mapping Logic
                if part.key == "得"
                  part_val = ""

                  # 1. Verb + De + Adj/Adv -> "Chay Nhanh" (Drop De)
                  if head.verb? && (compl.adj? || compl.adverb?)
                    part_val = ""
                    # 2. Adj + De + Verb -> "Vui den muc nhay" (State)
                  elsif head.adj? && (compl.verb? || compl.tag == PosTag::VCo)
                    part_val = "đến mức"
                    # 3. Adj + De + Adj -> "Nong den chet" (Degree)
                  elsif head.adj? && compl.adj?
                    part_val = "đến mức"
                    # 4. Verb + De + Verb -> Potential? (Listen Understand)
                  elsif head.verb? && compl.verb?
                    part_val = ""
                  end

                  part.val = part_val
                end

                # Case B: Potential (De/Bu + Verb/Result) e.g. "Ting De Dong", "Ting Bu Dong"
                if compl.verb? || compl.tag == PosTag::VCo # Result verb
                  # "Ting De Dong" -> "Nghe Hieu" (Drop De? Or "Nghe duoc hieu" is weird)
                  # Usually "Nghe hieu" (Can understand).
                  # "Ting Bu Dong" -> "Nghe khong hieu".

                  if part.key == "得"
                    # part.val already handled above?
                    # If part val is empty, it's fine.
                    # If we want explicit "duoc":
                    # part.val = "được"
                    # But "Nghe duoc hieu" is weird.
                    # Just "Nghe Hieu" implies potential.
                  elsif part.key == "不"
                    part.val = "không"
                  end
                end

                parent.children << head
                unless part.val.empty?
                  parent.children << part
                end
                parent.children << compl

                new_nodes << parent
                i += 3
                next
              end
            end
          end
        end

        # 2. Directional Complement Fusion: [Verb] [Dir1] [Dir2]
        # "Pao Jin Lai" -> "Chay Vao". (Drop Lai/Qu usually if Vao is clear, or fusion)
        if (verb = nodes[i]) && verb.verb?
          if (dir1 = nodes[i + 1]?) && (dir1.key == "进" || dir1.key == "出" || dir1.key == "上" || dir1.key == "下" || dir1.key == "回")
            if (dir2 = nodes[i + 2]?) && (dir2.key == "来" || dir2.key == "去")
              # Fusion: Jin Lai -> Vao. Chu Lai -> Ra.
              # "Pao Jin Lai" -> "Chay Vao".

              parent = MtNode.new("", PosTag::Verb)
              parent.children << verb
              parent.children << dir1
              # Skip dir2 (Lai/Qu) commonly in VN unless specific logic needed

              new_nodes << parent
              i += 3
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
