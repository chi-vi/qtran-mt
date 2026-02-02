module QTran
  enum PosTag
    None # Unknown or uninitialized

    # Nouns
    Noun    # n
    NDir    # nd (direction)
    NTime   # nt (time)
    NPlace  # nl (location)
    NPerson # nh (person)
    NSkill  # nz (specialized/skill?) - Check mapping, usually 'nz' is other proper noun
    NIdeo   # ni (idiom?) - Check LTP mapping. 'ni' is organization name in LTP.

    # Verbs
    Verb   # v
    VCo    # v + compl? or coverb?
    VModal # opt / v_modal

    # Adjectives
    Adj     # a
    AdjStat # z (status adjective)

    # Pronouns
    Pronoun # r

    # Adverbs
    Adverb # d

    # Prepositions
    Prepos # p

    # Conjunctions
    Conj # c

    # Particles
    Part   # u
    PartDe # de (u)
    PartLe # le (u)

    # Numerals / Quantifiers
    Number # m
    Quant  # q

    # Punctuation
    Punct # wp

    # Special
    LitStr # For literals
    UrlStr # For URLs

    def self.from_ltp(tag : ::String) : PosTag
      case tag
      when "n"      then Noun
      when "nd"     then NDir
      when "nt"     then NTime
      when "nl"     then NPlace
      when "nh"     then NPerson
      when "ni"     then NIdeo  # Organization name
      when "nz"     then NSkill # Other proper noun
      when "v"      then Verb
      when "a", "b" then Adj # b is distintive word, treated as adj often
      when "z"      then AdjStat
      when "r"      then Pronoun
      when "d"      then Adverb
      when "p"      then Prepos
      when "c"      then Conj
      when "u"      then Part
      when "m"      then Number
      when "q"      then Quant
      when "wp"     then Punct
      else               None
      end
    end

    def noun?
      self.in?(Noun, NDir, NTime, NPlace, NPerson, NSkill, NIdeo)
    end

    def n_dir?
      self == NDir
    end

    def n_person?
      self == NPerson || self == Pronoun # Pronoun is r, but sometimes treated as person for rules
    end

    def verb?
      self.in?(Verb, VCo, VModal)
    end

    def adj?
      self.in?(Adj, AdjStat)
    end

    def pronoun?
      self == Pronoun
    end

    def prepos?
      self == Prepos
    end

    def conj?
      self == Conj
    end

    def part_de?
      self == PartDe || (self == Part && true) # How to distinguish 'de' from generic Part if from_ltp maps to Part?
      # LTP 'u' maps to Part. But logic elsewhere checks key "de" too.
      # Ideally we refine from_ltp or rely on key check.
      # For now:
      self == PartDe || self == Part
    end
  end
end
