require "../node"
require "../pos_tag"
require "./de_resolver"

module QTran
  module NounRules
    extend self

    def apply(nodes : Array(MtNode)) : Array(MtNode)
      new_nodes = [] of MtNode
      i = 0

      while i < nodes.size
        # 0. Conjunction Grouping (Greedy)
        if (n1 = nodes[i]) && (conj = nodes[i + 1]?) && (n2 = nodes[i + 2]?)
          # Remove comma "," from grouping to prevent clause bleeding
          is_list_sep = conj.tag.conj? || (conj.tag == PosTag::Punct && conj.key == "、")

          if is_list_sep
            # Check types
            if (n1.adj? && n2.adj?) || (n1.verb? && n2.verb?) || (n1.noun? && n2.noun?)
              parent = MtNode.new("", n1.tag) # Inherit type
              parent.children << n1
              parent.children << conj
              parent.children << n2

              new_nodes << parent
              i += 3
              next
            end
          end
        end

        # 1. Attributive/Adverbial/RelClause: [Phrase] + de + [Head]
        # Match: [N1] [de] [N2]
        if (n1 = nodes[i]) && (de = nodes[i + 1]?) && (n2 = nodes[i + 2]?)
          if (de.key == "的" || de.key == "地" || de.key == "之")
            # Check N2 head
            if n2.noun? || n2.pronoun? || n2.verb?
              modifier = n1

              # Special Logic: Relative Clause with Subject?
              # "Subject + Verb" or "Subject + Suo + Verb"
              if n1.verb?
                if (subject = new_nodes.last?)
                  if subject.noun? || subject.pronoun?
                    # Standard S + V
                    phrase = MtNode.new("", PosTag::Verb)
                    phrase.children << subject
                    phrase.children << n1
                    new_nodes.pop
                    modifier = phrase
                  elsif subject.key == "所" || subject.tag == PosTag::Part
                    # Check for Subject before Suo: "S + Suo + V"
                    suo = subject
                    new_nodes.pop # Pop Suo
                    if (real_subj = new_nodes.last?) && (real_subj.noun? || real_subj.pronoun?)
                      phrase = MtNode.new("", PosTag::Verb)
                      phrase.children << real_subj
                      phrase.children << suo
                      phrase.children << n1
                      new_nodes.pop # Pop Subject
                      modifier = phrase
                    else
                      # Just "Suo + V" (Passive marker or nominalizer)
                      # Treat Suo+V as the modifier unit
                      phrase = MtNode.new("", PosTag::Verb)
                      phrase.children << suo
                      phrase.children << n1
                      modifier = phrase
                    end
                  end
                end
              elsif n1.noun? || n1.pronoun?
                # Special Logic: "Verb + Object + De + Head"
                # Only trigger if Head (n2) is Person to avoid capturing Main Verb + Object
                is_person_head = n2.tag.n_person? || WordClassifier.person?(n2.key, n2.tag)

                if is_person_head && (verb = new_nodes.last?) && verb.verb?
                  phrase = MtNode.new("", PosTag::Verb)
                  phrase.children << verb
                  phrase.children << n1
                  new_nodes.pop # Pop Verb
                  modifier = phrase
                end
              end

              # Check modifier validity
              if modifier.noun? || modifier.verb? || modifier.adj? || modifier.pronoun?
                # Inherit head tag (Verb/Noun) instead of hardcoding Noun
                parent = MtNode.new("", n2.tag)

                de_val = ""

                if de.key == "地"
                  de_val = "" # Adverbial 'de'
                else
                  # Use DeResolver for 'de'/'zhi'
                  de_val = DeResolver.resolve(modifier, de)
                end

                # Special override: Relative clause "de", often empty
                if modifier.verb? && de.key == "的"
                  de_val = ""
                end

                de.val = de_val

                # Swap: [Head] [de] [Modifier]
                parent.children << n2
                unless de_val.empty?
                  parent.children << de
                end
                parent.children << modifier

                new_nodes << parent
                i += 3
                next
              end
            end
          end
        end

        # 2. Adj + Noun
        if (adj = nodes[i]) && (noun = nodes[i + 1]?)
          if adj.adj? && noun.noun?
            # Exception: "Zhengge" (Whole) - Do NOT swap
            if adj.key == "整个"
              # Keep as Adj + Noun
              parent = MtNode.new("", PosTag::Noun)
              parent.children << adj
              parent.children << noun
              new_nodes << parent
              i += 2
              next
            end

            parent = MtNode.new("", PosTag::Noun)
            parent.children << noun
            parent.children << adj

            new_nodes << parent
            i += 2
            next
          end
        end

        # 3. Noun + Localizer
        if (noun = nodes[i]) && (loc = nodes[i + 1]?)
          if noun.noun? && loc.n_dir?
            parent = MtNode.new("", PosTag::NDir)
            parent.children << loc
            parent.children << noun

            new_nodes << parent
            i += 2
            next
          end
        end

        # 4. Noun + Noun
        if (n1 = nodes[i]) && (n2 = nodes[i + 1]?)
          # Allow Time+Time swap
          should_swap = false
          if (n1.noun? || n1.pronoun?) && (n2.noun? || n2.pronoun?)
            # Exclude Zheme/Name from noun compounding (they are treated as adverbs/comparisons later)
            if n2.key == "这么" || n2.key == "那么"
              new_nodes << nodes[i]
              i += 1
              next
            end

            # Prevent swapping "NTime NTime" if logic requires

            # Special override for Time
            if n1.tag == PosTag::NTime && n2.tag == PosTag::NTime
              should_swap = true
            end

            # General Noun/Pronoun Modifiers handling
            # Always swap Mod + Head -> Head + Mod
            if n1.noun? && n2.noun? && !should_swap
              should_swap = true
            end

            # Special Logic for Pronoun + Noun
            if n1.pronoun? && (n2.noun? || n2.tag.n_person? || n2.tag.n_place? || n2.tag.n_org? || n2.pronoun?)
              # Check if n2 is possessable/relationship
              if WordClassifier.person?(n2.key, n2.tag) ||
                 WordClassifier.place?(n2.key, n2.tag) ||
                 WordClassifier.org?(n2.key, n2.tag) ||
                 n2.key == "自己" # Force swap for Ziji
                should_swap = true
              end
            end
          end

          if should_swap
            parent = MtNode.new("", PosTag::Noun)
            parent.children << n2
            parent.children << n1

            new_nodes << parent
            i += 2
            next
          end
        end

        # 5. Possessive End-Phrase Adjustment (Dangling De)
        # Match: [Pronoun/Noun] + [de] (and Rule 1 didn't match)
        # "Wo de" -> "Cua toi"
        if (n1 = nodes[i]) && (de = nodes[i + 1]?)
          if (de.key == "的" || de.key == "之") && (n1.pronoun? || n1.noun?)
            parent = MtNode.new("", PosTag::Adj) # Treated as Modifier Phrase

            # Force 'cua'
            de.val = "của"

            parent.children << de
            parent.children << n1

            new_nodes << parent
            i += 2
            next
          end
        end

        new_nodes << nodes[i]
        i += 1
      end

      new_nodes
    end
  end
end
