require "../node"
require "../pos_tag"

module QTran
  # Phase 0.2: Number Rules (Num + Quant + Noun -> Noun + Num + Quant)
  module NumberRules
    extend self

    def apply(nodes : Array(MtNode)) : Array(MtNode)
      new_nodes = [] of MtNode
      i = 0

      while i < nodes.size
        # 1. Num + Quant + Noun -> Noun + Num + Quant
        if (num = nodes[i]) && (num.tag == PosTag::Number)
          if (quant = nodes[i + 1]?) && (quant.tag == PosTag::Quant)
            if (noun = nodes[i + 2]?) && (noun.noun? || noun.tag == PosTag::NTime)
              parent = MtNode.new("", PosTag::Noun)

              # Logic: Drop 'Ge' (Cai) if Noun is Time (XiaoShi=Tieng, Mingtian=...)
              if quant.key == "个"
                if noun.tag == PosTag::NTime || noun.key == "小时" || noun.key == "钟头"
                  quant.val = ""
                end
              end

              if quant.val.empty?
                parent.children << num
                parent.children << noun
              else
                # Keep [Num] [Quant] [Noun] for standard counting
                # "1 Quyen Sach" -> "1 Quyen Sach"
                parent.children << num
                parent.children << quant
                parent.children << noun
              end

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
