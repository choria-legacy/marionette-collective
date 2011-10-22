module MCollective
  # A parser and scanner that creates a stack machine for a simple
  # fact and class matching language used on the CLI to facilitate
  # a rich discovery language
  #
  # Language EBNF
  #
  # compound = ["("] expression [")"] {["("] expression [")"]}
  # expression = [!|not]statement ["and"|"or"] [!|not] statement
  # char = A-Z | a-z | < | > | => | =< | _ | - |* | / { A-Z | a-z | < | > | => | =< | _ | - | * | / | }
  # int = 0|1|2|3|4|5|6|7|8|9{|0|1|2|3|4|5|6|7|8|9|0}
  module Matcher
    autoload :Parser, "mcollective/matcher/parser"
    autoload :Scanner, "mcollective/matcher/scanner"
  end
end
