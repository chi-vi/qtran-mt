require "../node"
require "../pos_tag"

module QTran
  module NounRules
    extend self

    def apply(nodes : Array(MtNode)) : Array(MtNode)
      new_nodes = [] of MtNode
      i = 0

      while i < nodes.size
        # 0. Conjunction Grouping (Greedy)
        if (n1 = nodes[i]) && (conj = nodes[i + 1]?) && (n2 = nodes[i + 2]?)
          if conj.tag.conj?
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
              # If n1 is Verb, check if we have a Subject pending in new_nodes
              if n1.verb? && (subject = new_nodes.last?) && (subject.noun? || subject.pronoun?)
                # Capturing Subject for Relative Clause
                # Create a Phrase node for [Subject + Verb]
                phrase = MtNode.new("", PosTag::Verb)
                phrase.children << subject
                phrase.children << n1

                # Remove subject from new_nodes output
                new_nodes.pop

                modifier = phrase
              end

              # Check modifier validity
              if modifier.noun? || modifier.verb? || modifier.adj? || modifier.pronoun?
                parent = MtNode.new("", PosTag::Noun) # Generic Noun Phrase

                de_val = (de.key == "地") ? "" : "của"
                if (modifier.adj? || de.key == "地")
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
          if n1.noun? && n2.noun? && !n2.n_person? && !n1.n_person?
            parent = MtNode.new("", PosTag::Noun)
            parent.children << n2
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
