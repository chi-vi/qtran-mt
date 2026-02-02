require "../node"
require "../pos_tag"

module QTran
  module NounRules
    extend self

    def apply(node : MtNode) : MtNode
      # Check for [Phrase Head] + de (Attributive or Adverbial)
      # Covers: Noun+de, Verb+de, Adj+de
      if (node.noun? || node.pronoun? || node.verb? || node.adj?) &&
         (succ = node.succ) &&
         (succ.part_de? || succ.key == "的" || succ.key == "地" || succ.key == "之")
        return fold_noun_group(node)
      end

      case node.tag
      when .adj?
        fold_adj_noun(node)
      when .noun?, .pronoun?
        fold_noun_group(node)
      else
        node
      end
    end

    # Rule: Adj + Noun -> Noun + Adj
    def fold_adj_noun(node : MtNode) : MtNode
      succ = node.succ
      return node unless succ

      if succ.noun?
        # Simple Adj swap
        node.remove!
        succ.insert_after(node)
        return succ
      end

      node
    end

    # Rule: N1 + de + N2 -> N2 + (của) + N1
    # Rule: Verb + de + Noun -> Noun + (của) + Verb (Relative Clause)
    # Rule: N1 + N2 -> N2 + N1 (if not person, etc.)
    def fold_noun_group(node : MtNode) : MtNode
      succ = node.succ
      return node unless succ

      # Case: Noun/Verb + de + Noun
      if (succ.key == "的" || succ.key == "地" || succ.tag.part_de?) && succ.val != "của" && succ.val != "mà"
        # N1(node) -> de(succ) -> N2(?)
        noun2 = succ.succ

        # Check if N2 is valid noun(-phrase) head or VERB (for adverbial mod)
        if noun2 && (noun2.noun? || noun2.pronoun? || noun2.verb?)
          # Expand N1 leftwards to capture phrase (Subject + Adverb + Verb...)
          # e.g. [Wo] [Zuotian] [Mai]
          n1_start = node
          curr = node.prev

          # Heuristic: greedy expand left while seeing Noun/Pronoun/Time/Adverb
          # Stop at punctuation, 'de', or start of sentence
          while curr
            tag = curr.tag
            break if tag.punct? || tag.part_de?

            # Acceptable phrase components: include Adj and Conj
            if tag.noun? || tag.pronoun? || tag.n_time? || tag.adverb? || tag.verb? || tag.adj? || tag.conj?
              n1_start = curr
              curr = curr.prev
            else
              break
            end
          end

          # Check if the captured phrase is purely Adjective/Adverb/Conj
          # If so, we omit 'de' (val = "")
          is_pure_adj = true
          checker = n1_start
          while checker != succ  # Stop when we reach 'de'
            break unless checker # Safety check

            if checker.tag.noun? || checker.tag.pronoun? || checker.tag.verb? || checker.tag.n_time?
              # Found noun/verb -> Not pure adj
              is_pure_adj = false
              break
            end
            checker = checker.succ
          end

          # 1. Detach N2
          noun2.remove!

          # 2. Insert N2 before n1_start
          n1_start.insert_before(noun2)

          # 3. Insert de after N2 (before n1_start)
          # Only if not 'de' (Adverbial) or Pure Adj check

          if succ.key == "地" || is_pure_adj
            succ.remove! # Completely remove 'de' node for natural VN
          else
            succ.remove!             # Remove from old spot
            noun2.insert_after(succ) # Insert in new spot
            succ.val = "của"
            succ.tag = PosTag::Part
          end

          return noun2
        end
      end

      # Noun + Localizer (NDir) -> Localizer + Noun
      if succ.tag.n_dir?
        node.remove!
        succ.insert_after(node)
        return node
      end

      # Noun + Noun swap
      if node.noun? && succ.noun? && !succ.tag.n_person? && !node.tag.n_person?
        node.remove!
        succ.insert_after(node)
        return node
      end

      node
    end
  end
end
