require "../node"
require "../pos_tag"

module QTran
  module PreposRules
    extend self

    def apply(node : MtNode) : MtNode
      if node.tag.prepos? && (node.key == "在" || node.key == "于")
        fold_zai(node)
      else
        node
      end
    end

    def fold_zai(zai_node : MtNode) : MtNode
      # Pattern: [Zai] [Loc] [V] ...
      # VN: [V] ... (tại/ở) [Loc]

      # 1. Identify Loc
      loc = zai_node.succ
      return zai_node unless loc

      # If Loc is actually a phrase? Assuming single node or handled chunk for now.
      # If [Zai] is following a verb (Zhu zai Beijing), it's already [V] [Prep] [Loc]. Correct.
      # We only care if [Zai] is BEFORE the main verb.

      # Check previous
      prev = zai_node.prev
      if prev && prev.verb?
        # "Zhu zai ..." -> "Sống ở ...". Fine.
        zai_node.val = "ở"
        return zai_node
      end

      # Search for Verb after Loc
      # 2. Check for Verb following Loc
      # Allow intervening modifiers, or Ba/Bei constructions
      verb = loc.succ
      while verb && !verb.verb?
        # Stop if we hit punctuation or another preposition?
        # Actually Ba is Prepos. We should skip over Ba/Obj to find Verb.
        break if verb.tag.punct?
        verb = verb.succ
      end

      if verb && verb.verb?
        # Found Verb: [Zai] [Loc] ... [Verb]
        # Move [Zai Loc] to after [Verb] (and its object?)

        # Identify resumption point (node after Loc, which will shift left)
        resume_node = loc.succ

        # Detach Zai
        zai_node.remove!
        # Detach Loc
        loc.remove!

        # Insert Zai after Verb (or Object if V+Obj)
        target = verb
        if (obj = verb.succ) && (obj.noun? || obj.pronoun?)
          target = obj
        end

        target.insert_after(zai_node)

        # Insert Loc after Zai
        zai_node.insert_after(loc)

        zai_node.val = "ở"

        return resume_node || verb # Resume from what used to be after Loc
      end

      zai_node.val = "ở"
      zai_node
    end
  end
end
