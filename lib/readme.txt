program ::= <form>* <eof>

form ::= <declaration>
        | <expression>

  declaration ::= val <identifier> <- <expression>

  expression ::= <let>
                | <if>
                | <fn>
                | <call>
                | <literal>
                | <grouping>
                | <binary>
                | <unary>
                | <variable>
    variable ::= <identifier>

    let ::= let <form>* in <expression> end

    if ::= if <expression> then <expression> else <expression>

    fn ::= fn ( <args> ) <- <expression> 

    call ::= <identifier> ( <args> )

    literal ::= <list>
                | <integer>
                | <float>
                | <string>
                | <identifier>
                | <keyword>
                | <hashmap>
                | <atom>

      atom ::= :<identifier>

      list ::= [ <args>* ]

      hashmap ::= { <key_val>* }
        key_val ::= <atom> <literal>

args ::= [<atom>,]* <atom>

