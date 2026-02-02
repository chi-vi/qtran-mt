require "../node"
require "../pos_tag"

module QTran
  module VerbRules
    extend self

    def apply(nodes : Array(MtNode)) : Array(MtNode)
      new_nodes = [] of MtNode
      i = 0

      while i < nodes.size
        # 1a. Time + Verb -> Verb + Time
        if (time = nodes[i]) && (verb = nodes[i + 1]?)
          if time.n_time? && verb.verb?
            parent = MtNode.new("", PosTag::Verb) # Verb Group
            parent.children << verb
            parent.children << time

            new_nodes << parent
            i += 2
            next
          end
        end

        # 1b. Time + Subject + Verb -> Subject + Verb + (Obj) + Time
        if (time = nodes[i]) && (subj = nodes[i + 1]?) && (verb = nodes[i + 2]?)
          if time.n_time? && (subj.noun? || subj.pronoun?) && verb.verb?
            # Check for Object
            obj = nodes[i + 3]?
            # DEBUG PRINT
            # puts "DEBUG: TimeShuffle checking Obj at #{i+3}: #{obj.try(&.key)} (#{obj.try(&.tag)})"

            has_obj = obj && (obj.noun? || obj.pronoun?)

            parent = MtNode.new("", PosTag::Verb)
            # Output: Subject + Verb + (Obj) + Time
            parent.children << subj
            parent.children << verb
            if has_obj && obj
              # puts "DEBUG: Consuming Object #{obj.key}"
              parent.children << obj
            end
            parent.children << time

            new_nodes << parent
            i += (has_obj ? 4 : 3)
            next
          end
        end

        # 2. Ba Construction: [Ba] [Obj] [Verb] -> [Verb] [Obj]
        if (ba = nodes[i]) && (obj = nodes[i + 1]?) && (verb = nodes[i + 2]?)
          if ba.tag.prepos? && (ba.key == "把" || ba.key == "将") &&
             (obj.noun? || obj.pronoun?) &&
             verb.verb?
            parent = MtNode.new("", PosTag::Verb)
            # Output: Verb + Obj
            parent.children << verb
            parent.children << obj

            new_nodes << parent
            i += 3
            next
          end
        end

        # 3. Bei Construction: [Bei] [Agent] [Verb] -> [Bei] [Agent] [Verb]
        if (bei = nodes[i]) && (agent = nodes[i + 1]?)
          if bei.tag.prepos? && (bei.key == "被" || bei.key == "叫" || bei.key == "让")
            if (verb = nodes[i + 2]?) && verb.verb?
              parent = MtNode.new("", PosTag::Verb) # Passive Verb Group

              bei.val = "bị" # Default

              parent.children << bei
              parent.children << agent
              parent.children << verb

              new_nodes << parent
              i += 3
              next
            end
          end
        end

        # 4. Verb + Particles (Le, Guo, Zhe) check
        # This is strictly [Verb] [Part]
        if (verb = nodes[i]) && (part = nodes[i + 1]?)
          if verb.verb?
            handled = false
            parent = MtNode.new("", PosTag::Verb) # Prepare parent, use valid key/val if needed

            case part.key
            when "了"
              # V + Le (completed) -> Đã + V + (Obj handled later?)
              # User wants "Ate [a] Rice" -> "Đã ăn cơm".
              # Input tree: [Eat] [Le] -> reduced to P([Eat] [Le]).
              # Output Order: [Le(Đã)] [Eat].

              part.val = "đã"
              parent.children << part # Prefix: [Da] [Verb]
              parent.children << verb
              handled = true
            when "着"
              # V + Zhe -> Dang + V
              part.val = "đang"
              parent.children << part # Dang before V
              parent.children << verb
              handled = true
            when "过"
              # V + Guo -> Da Tung + V
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

        # Default
        new_nodes << nodes[i]
        i += 1
      end

      new_nodes
    end
  end
end
