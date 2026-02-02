require "../node"
require "../pos_tag"

module QTran
  module VerbRules
    extend self

    def apply(nodes : Array(MtNode)) : Array(MtNode)
      new_nodes = [] of MtNode
      i = 0

      while i < nodes.size
        # 0.1 SOV -> SVO Reordering (Topic Comment)
        # Match: [Probable Subject] [Probable Object] [Verb]
        # "Ta Hanyu Shuo..."
        if (subj = nodes[i]) && (obj = nodes[i + 1]?) && (verb = nodes[i + 2]?)
          if (subj.pronoun? || subj.tag == PosTag::Noun) && (obj.tag == PosTag::Noun) && verb.verb?
            # Check for implicit SOV.
            # "Ta Hanyu Shuo".
            # Swap Obj+Verb -> Verb+Obj.

            # Need to be careful not to break "Adj + Noun" or "Noun + Noun" compounds.
            # But "Hanyu Shuo" (Chinese Speak) -> "Speak Chinese".
            # Output: [Subj] [Verb] [Obj]

            # We consume Subj, Obj, Verb.
            # Create Phrase? No, just reordered stream.
            new_nodes << subj
            new_nodes << verb
            new_nodes << obj

            i += 3
            next
          end
        end

        # 0. Time + Verb Reordering
        # Also Time + Subject -> Subject + Time

        # Check Time Node
        is_time = false
        time = nodes[i]
        if time
          if time.tag == PosTag::NTime || (time.tag == PosTag::Noun && (time.key == "明天" || time.key == "昨天" || time.key == "今天" || time.key == "今年"))
            is_time = true
          end
        end

        if is_time && time # Helper check
          # Case A: Time + Verb -> Verb + Time
          if (verb = nodes[i + 1]?) && verb.verb?
            parent = MtNode.new("", PosTag::Verb)

            # Check for Object after Verb
            # Match: [Time] [Verb] [Obj] -> [Verb] [Obj] [Time]
            # VN: "Hom qua ta di thu vien" is natural, but "Ta di thu vien hom qua" is also good.
            # Current logic swaps [Time] [Verb] -> [Verb] [Time].
            # If we have [Verb] [Time] [Obj], it becomes "Di hom qua thu vien" (Bad).
            # So if we swap, we MUST put Time *after* Object if Object exists.

            idx_obj = i + 2
            has_obj = false
            obj = nodes[idx_obj]?
            if obj && (obj.noun? || obj.pronoun?)
              has_obj = true
            end

            parent.children << verb
            if has_obj && obj
              parent.children << obj
            end
            parent.children << time

            new_nodes << parent
            i += (has_obj ? 3 : 2)
            next
          end

          # Case B: Time + Subject -> Subject + Time (Noun/Pronoun)
          # "ZuoTian Wo" -> "Wo ZuoTian"
          # Avoid swapping if Subject is also Time (Time + Time compound)
          if (subj = nodes[i + 1]?) && (subj.noun? || subj.pronoun?)
            should_swap = true
            if subj.tag == PosTag::NTime
              should_swap = false
            end

            if should_swap
              # Swap order in output
              new_nodes << subj
              new_nodes << time
              i += 2
              next
            end
          end
        end

        # 1. Ba/Bei Constructions
        if (prep = nodes[i]) && (obj = nodes[i + 1]?) && (verb = nodes[i + 2]?)
          # Ba: A Ba B V -> A V B
          if prep.key == "把" && (obj.noun? || obj.pronoun?) && verb.verb?
            parent = MtNode.new("", PosTag::Verb)

            # Check particle [Le] after verb?
            if (part = nodes[i + 3]?) && (part.key == "了" || part.key == "着" || part.key == "过")
              part.val = (part.key == "了" || part.key == "过") ? "đã" : "đang"
              parent.children << part
              i += 4
            else
              i += 3
            end

            parent.children << verb
            parent.children << obj

            new_nodes << parent
            next
          end

          # Bei: A Bei B V -> A Bi B V
          if prep.key == "被" && (obj.noun? || obj.pronoun?) && verb.verb?
            parent = MtNode.new("", PosTag::Verb)

            # Prefix "Da/Dang" logic check
            has_le = false
            if (part = nodes[i + 3]?) && (part.key == "了" || part.key == "着" || part.key == "过")
              part_val = (part.key == "了" || part.key == "过") ? "đã" : "đang"
              part.val = part_val
              parent.children << part
              has_le = true
            end

            prep.val = "bị"
            parent.children << prep
            parent.children << obj
            parent.children << verb

            new_nodes << parent
            i += (has_le ? 4 : 3)
            next
          end
        end

        # 2. Verb + Particle
        # Match: [Verb] + [Le/Zhe/Guo]
        if (verb = nodes[i]) && (part = nodes[i + 1]?)
          if verb.verb? && (part.tag == PosTag::PartLe || part.key == "了" || part.key == "着" || part.key == "过")
            parent = MtNode.new("", PosTag::Verb)
            handled = false

            case part.key
            when "了"
              part.val = "đã"
              parent.children << part # Prefix: [Da] [Verb]
              parent.children << verb
              handled = true
            when "着"
              part.val = "đang"
              parent.children << part
              parent.children << verb
              handled = true
            when "过"
              part.val = "đã từng"
              parent.children << part
              parent.children << verb
              handled = true
            end

            if handled
              new_nodes << parent
              i += 2
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
