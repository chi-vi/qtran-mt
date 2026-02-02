require "../node"
require "../pos_tag"

module QTran
  module VerbRules
    extend self

    def apply(node : MtNode) : MtNode
      # Handle 'Ba' construction: Subj + Ba + Obj + V -> Subj + V + Obj
      # Handle Time + Verb -> Verb + Time
      if node.tag.n_time?
        return fold_time_verb(node)
      end

      # Handle Ba/Bei which are Prepositions but handled here for Verb structures
      if node.tag.prepos?
        if node.key == "把" || node.key == "将"
          return fold_ba(node)
        elsif node.key == "被" || node.key == "叫" || node.key == "让"
          return fold_bei(node)
        end
      end

      case node.tag
      when .verb?, .v_co?, .v_modal?
        fold_verb_group(node)
      else
        node
      end
    end

    # Rule: Time + Verb -> Verb + Time
    # e.g. [Zuotian] [Mai] -> [Mai] [Zuotian]
    def fold_time_verb(node : MtNode) : MtNode
      succ = node.succ
      return node unless succ

      if succ.verb?
        # Swap
        node.remove!
        succ.insert_after(node)
        return succ # Focus on Verb
      end

      node
    end

    def fold_ba(ba_node : MtNode) : MtNode
      # Pattern: ... [Ba] [Obj] [V] ...
      # Goal: ... [V] [Obj] ... (Delete Ba)

      obj = ba_node.succ
      return ba_node unless obj && (obj.noun? || obj.pronoun?)

      verb = obj.succ
      # Skip adverbs/negation between obj and verb?
      # "Ba + Obj + (Adv) + V" is rare? Usually "Adv + Ba + Obj + V"
      # But sometimes "Ba + Obj + bu + V" ? No.

      return ba_node unless verb && verb.verb?

      # Operation:
      # 1. Remove Ba
      # 2. Remove Obj
      # 3. Insert Obj after Verb

      ba_node.remove! # Ba is gone

      obj.remove!
      verb.insert_after(obj)

      # Return verb to continue processing from verb
      return verb
    end

    def fold_bei(bei_node : MtNode) : MtNode
      # Pattern: [Bei] [Agent] [V]
      # VN: [Bị/Được] [Agent] [V]
      # Just translate 'Bei'.

      # "被" -> "bị" (negative) or "được" (positive)
      # Heuristic: Default to "bị" unless verb is positive?
      # For now, "bị".

      bei_node.val = "bị"

      # Sometimes Agent is omitted in Chinese: "Pingguo bei chi le" (Apple was eaten)
      # VN: "Táo bị ăn rồi" (Same structure)

      bei_node
    end

    def fold_verb_group(verb : MtNode) : MtNode
      succ = verb.succ
      return verb unless succ

      case succ.key
      when "了" # le -> đã (pre-verb) or rồi (sentence end)
        # If immediately after verb: "Chi le fan" -> "Ăn cơm rồi" or "Đã ăn cơm"
        # Simplest: "Chi le" -> "Ăn rồi"
        succ.val = "rồi"
        # Move 'le' to end of sentence? Or keep after verb?
        # VN: "Ăn rồi" (V + part). Ok.

      when "过" # guo -> qua / đã từng
        succ.val = "qua"
        # "Qu guo Beijing" -> "Đi qua BK" or "Đi BK qua"?
        # Actually "đã từng đi BK".
        # Let's try: Move 'guo' to before verb and change to "đã từng"
        succ.remove!
        verb.insert_before(succ)
        succ.val = "đã từng"
        return succ # Process from new start

      when "着" # zhe -> đang
        succ.remove!
        verb.insert_before(succ)
        succ.val = "đang"
        return succ
      when "不" # bu -> không
        # Usually occurs BEFORE verb in Chinese: "Bu chi"
        # VN: "Không ăn". Same order.
        # But if "Verb + bu + Compl" (Kan bu jian) -> "Nhìn không thấy"
        # Need to handle potential verb-complement structures if 'bu' is handled as separate node
      end

      # Handle pre-verb Negation if current node is "Bu" or "Mei" (Wait, current node is Verb)
      # So we need to look at PREVIOUS for negation?
      # Or we iterate and find 'Bu' then look for Verb?
      # Currently we iterate all nodes. So when we hit 'Bu', we handle it.

      verb
    end
  end
end
