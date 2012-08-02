# :title: Text::Reform
# :main: Text::Reform
#--
# Text::Reform for Ruby
# Version 0.2.0
#
# Copyright (c) 2004 by Kaspar Schiess
#
# $Id: reform.rb,v 1.1.1.1 2005/01/18 11:15:51 eule Exp $
#++

require 'scanf'
unless defined?(Text)
  module Text; end
end

  # = Introduction
  #
  # Text::Reform class is a rewrite from the perl module with the same name
  # by Damian Conway (damian@conway.org). Much of this documentation has
  # been copied from the original documentation and adapted to the Ruby
  # version.
  #
  # The interface is subject to change, since it will undergo major
  # Rubyfication.
  #
  # = Synopsis
  #   require 'text/reform'
  #   f = Text::Reform.new
  #
  #   puts f.format(template, data)
  #
  # = Description
  # == The Reform#format method
  #
  # Reform#format takes a series of format (or "picture") strings followed
  # by replacement values, interpolates those values into each picture
  # string, and returns the result.
  #
  # A picture string consists of sequences of the following characters:
  # [<]                   Left-justified field indicator. A series of two or
  #                       more sequential +<+'s specify a left-justified
  #                       field to be filled by a subsequent value. A single
  #                       +<+ is formatted as the literal character '<'.
  # [>]                   Right-justified field indicator. A series of two
  #                       or more sequential >'s specify a right-justified
  #                       field to be filled by a subsequent value. A single
  #                       < is formatted as the literal character '<'.
  # [<<>>]                Fully-justified field indicator. Field may be of
  #                       any width, and brackets need not balance, but
  #                       there must be at least 2 '<' and 2 '>'.
  # [^]                   Centre-justified field indicator. A series of two
  #                       or more sequential ^'s specify a centred field to
  #                       be filled by a subsequent value. A single ^ is
  #                       formatted as the literal character '<'.
  # [>>.<<<<]             A numerically formatted field with the specified
  #                       number of digits to either side of the decimal
  #                       place. See _Numerical formatting_ below.
  # [[]                   Left-justified block field indicator. Just like a
  #                       < field, except it repeats as required on
  #                       subsequent lines. See below. A single [ is
  #                       formatted as the literal character '['.
  # []]                   Right-justified block field indicator. Just like a
  #                       > field, except it repeats as required on
  #                       subsequent lines. See below. A single ] is
  #                       formatted as the literal character ']'.
  # [[[]]]                Fully-justified block field indicator. Just like a
  #                       <<<>>> field, except it repeats as required on
  #                       subsequent lines. See below. Field may be of any
  #                       width, and brackets need not balance, but there
  #                       must be at least 2 '[' and 2 ']'.
  # [|]                   Centre-justified block field indicator. Just like
  #                       a ^ field, except it repeats as required on
  #                       subsequent lines. See below. A single | is
  #                       formatted as the literal character '|'.
  # []]].[[[[]            A numerically formatted block field with the
  #                       specified number of digits to either side of the
  #                       decimal place. Just like a +>>>.<<<<+ field,
  #                       except it repeats as required on subsequent lines.
  #                       See below.
  # [~]                   A one-character wide block field.
  # [\]                   Literal escape of next character (e.g. +\+ is
  #                       formatted as '~', not a one character wide block
  #                       field).
  # [Any other character] That literal character.
  #
  # Any substitution value which is +nil+ (either explicitly so, or because
  # it is missing) is replaced by an empty string.
  #
  # == Controlling Reform instance options
  # There are several ways to influence options set in the Reform instance:
  #
  # 1. At creation:
  #       # using a hash
  #     r1 = Text::Reform.new(:squeeze => true)
  #
  #       # using a block
  #     r2 = Text::Reform.new do |rf|
  #       rf.squeeze = true
  #       rf.fill    = true
  #     end
  #
  # 2. Using accessors:
  #     r         = Text::Reform.new
  #     r.squeeze = true
  #     r.fill    = true
  #
  # The Perl way of interleaving option changes with picture strings and
  # data is currently *NOT* supported.
  #
  # == Controlling line filling
  # #squeeze replaces sequences of spaces or tabs to be replaced with a
  # single space; #fill removes newlines from the input. To minimize all
  # whitespace, you need to specify both options. Hence:
  #
  #   format  = "EG> [[[[[[[[[[[[[[[[[[[[["
  #   data    = "h  e\t l lo\nworld\t\t\t\t\t"
  #   r         = Text::Reform.new
  #   r.squeeze = false # default, implied
  #   r.fill    = false # default, implied
  #   puts r.format(format, data)
  #     # all whitespace preserved:
  #     #
  #     # EG> h  e        l lo
  #     # EG> world
  #
  #   r.squeeze = true
  #   r.fill    = false # default, implied
  #   puts r.format(format, data)
  #     # only newlines preserved
  #     #
  #     # EG> h e l lo
  #     # EG> world
  #
  #   r.squeeze = false # default, implied
  #   r.fill    = true
  #   puts r.format(format, data)
  #     # only spaces/tabs preserved:
  #     #
  #     # EG> h  e        l lo world
  #
  #   r.fill    = true
  #   r.squeeze = true
  #   puts r.format(format, data)
  #     # no whitespace preserved:
  #     #
  #     # EG> h e l lo world
  #
  # Whether or not filling or squeezing is in effect, #format can also be
  # directed to trim any extra whitespace from the end of each line it
  # formats, using the #trim option. If this option is specified with a
  # +true+ value, every line returned by #format will automatically have the
  # substitution +.gsub!(/[ \t]+/, '')+ applied to it.
  #
  #   r.format("[[[[[[[[[[[", 'short').length # => 11
  #   r.trim = true
  #   r.format("[[[[[[[[[[[", 'short').length # => 6
  #
  # It is also possible to control the character used to fill lines that are
  # too short, using the #filler option. If this option is specified the
  # value of the #filler flag is used as the fill string, rather than the
  # default +" "+.
  #
  # For example:
  #   r.filler = '*'
  #   print r.format("Pay bearer: ^^^^^^^^^^^^^^^^^^^^", '$123.4')
  # prints:
  #   Pay bearer: *******$123.4*******
  #
  # If the filler string is longer than one character, it is truncated to
  # the appropriate length. So:
  #   r.filler = '-->'
  #   print r.format("Pay bearer: ^^^^^^^^^^^^^^^^^^^^", '$123.4')
  #   print r.format("Pay bearer: ^^^^^^^^^^^^^^^^^^^^", '$13.4')
  #   print r.format("Pay bearer: ^^^^^^^^^^^^^^^^^^^^", '$1.4')
  # prints:
  #   Pay bearer: -->-->-$123.4-->-->-
  #   Pay bearer: -->-->--$13.4-->-->-
  #   Pay bearer: -->-->--$1.4-->-->--
  #
  # If the value of the #filler option is a hash, then its +:left+ and
  # +:right+ entries specify separate filler strings for each side of an
  # interpolated value.
  #
  # == Options
  # The Perl variant supports option switching during processing of the
  # arguments of a single call to #format. This has been removed while
  # porting to Ruby, since I believe that this does not add to clarity
  # of code. So you have to change options explicitly.
  #
  # == Data argument types and handling
  # The +data+ part of the call to format can be either in String form, the
  # items being newline separated, or in Array form. The array form can
  # contain any kind of type you want, as long as it supports #to_s.
  #
  # So all of the following examples return the same result:
  #     # String form
  #   r.format("]]]].[[", "1234\n123")
  #     # Array form
  #   r.format("]]]].[[", [ 1234, 123 ])
  #     # Array with another type
  #   r.format("]]]].[[", [ 1234.0, 123.0 ])
  #
  # == Multi-line format specifiers and interleaving
  # By default, if a format specifier contains two or more lines (i.e. one
  # or more newline characters), the entire format specifier is repeatedly
  # filled as a unit, until all block fields have consumed their
  # corresponding arguments. For example, to build a simple look-up table:
  #   values = (1..12).to_a
  #   squares   = values.map { |el| sprintf "%.6g", el**2         }
  #   roots     = values.map { |el| sprintf "%.6g", Math.sqrt(el) }
  #   logs      = values.map { |el| sprintf "%.6g", Math.log(el)  }
  #   inverses  = values.map { |el| sprintf "%.6g", 1/el          }
  #
  #   puts reform.format(
  #     "  N      N**2    sqrt(N)      log(N)      1/N",
  #     "=====================================================",
  #     "| [[  |  [[[  |  [[[[[[[[[[ | [[[[[[[[[ | [[[[[[[[[ |" +
  #     "-----------------------------------------------------",
  #     values, squares, roots, logs, inverses
  #   )
  #
  # The multiline format specifier:
  #     "| [[  |  [[[  |  [[[[[[[[[[ | [[[[[[[[[ | [[[[[[[[[ |" +
  #     "-----------------------------------------------------"
  #
  # is treated as a single logical line. So #format alternately fills the
  # first physical line (interpolating one value from each of the arrays)
  # and the second physical line (which puts a line of dashes between each
  # row of the table) producing:
  #       N      N**2    sqrt(N)      log(N)      1/N
  #     =====================================================
  #     | 1   |  1    |  1          | 0         | 1         |
  #     -----------------------------------------------------
  #     | 2   |  4    |  1.41421    | 0.693147  | 0.5       |
  #     -----------------------------------------------------
  #     | 3   |  9    |  1.73205    | 1.09861   | 0.333333  |
  #     -----------------------------------------------------
  #     | 4   |  16   |  2          | 1.38629   | 0.25      |
  #     -----------------------------------------------------
  #     | 5   |  25   |  2.23607    | 1.60944   | 0.2       |
  #     -----------------------------------------------------
  #     | 6   |  36   |  2.44949    | 1.79176   | 0.166667  |
  #     -----------------------------------------------------
  #     | 7   |  49   |  2.64575    | 1.94591   | 0.142857  |
  #     -----------------------------------------------------
  #     | 8   |  64   |  2.82843    | 2.07944   | 0.125     |
  #     -----------------------------------------------------
  #     | 9   |  81   |  3          | 2.19722   | 0.111111  |
  #     -----------------------------------------------------
  #     | 10  |  100  |  3.16228    | 2.30259   | 0.1       |
  #     -----------------------------------------------------
  #     | 11  |  121  |  3.31662    | 2.3979    | 0.0909091 |
  #     -----------------------------------------------------
  #     | 12  |  144  |  3.4641     | 2.48491   | 0.0833333 |
  #     -----------------------------------------------------
  #
  # This implies that formats and the variables from which they're filled
  # need to be interleaved. That is, a multi-line specification like this:
  #   puts r.format(
  #     "Passed:                      ##
  #        [[[[[[[[[[[[[[[             # single format specification
  #     Failed:                        # (needs two sets of data)
  #        [[[[[[[[[[[[[[[",          ##
  #     passes, fails)                ##  data for previous format
  # would print:
  #      Passed:
  #         <pass 1>
  #      Failed:
  #         <fail 1>
  #      Passed:
  #         <pass 2>
  #      Failed:
  #         <fail 2>
  #      Passed:
  #         <pass 3>
  #      Failed:
  #         <fail 3>
  #
  # because the four-line format specifier is treated as a single unit, to
  # be repeatedly filled until all the data in +passes+ and +fails+ has been
  # consumed.
  #
  # Unlike the table example, where this unit filling correctly put a line
  # of dashes between lines of data, in this case the alternation of passes
  # and fails is probably /not/ the desired effect.
  #
  # Judging by the labels, it is far more likely that the user wanted:
  #      Passed:
  #         <pass 1>
  #         <pass 2>
  #         <pass 3>
  #      Failed:
  #         <fail 4>
  #         <fail 5>
  #         <fail 6>
  #
  # To achieve that, either explicitly interleave the formats and their data
  # sources:
  #   puts r.format(
  #     "Passed:",               ## single format (no data required)
  #     "   [[[[[[[[[[[[[[[",    ## single format (needs one set of data)
  #         passes,              ## data for previous format
  #     "Failed:",               ## single format (no data required)
  #     "   [[[[[[[[[[[[[[[",    ## single format (needs one set of data)
  #         fails)               ## data for previous format
  # or instruct #format to do it for you automagically, by setting the
  # 'interleave' flag +true+:
  #
  #     r.interleave = true
  #     puts r.format(
  #       "Passed:                ##
  #        [[[[[[[[[[[[[[[         # single format
  #     Failed:                    # (needs two sets of data)
  #        [[[[[[[[[[[[[[[",      ##
  #                               ## data to be automagically interleaved
  #        passes, fails)          # as necessary between lines of previous
  #                               ## format
  #
  # == How #format hyphenates
  # Any line with a block field repeats on subsequent lines until all block
  # fields on that line have consumed all their data. Non-block fields on
  # these lines are replaced by the appropriate number of spaces.
  #
  # Words are wrapped whole, unless they will not fit into the field at all,
  # in which case they are broken and (by default) hyphenated. Simple
  # hyphenation is used (i.e. break at the +N-1+th character and insert a
  # '-'), unless a suitable alternative subroutine is specified instead.
  #
  # Words will not be broken if the break would leave less than 2 characters
  # on the current line. This minimum can be varied by setting the
  # +min_break+ option to a numeric value indicating the minumum total broken
  # characters (including hyphens) required on the current line. Note that,
  # for very narrow fields, words will still be broken (but
  # __unhyphenated__). For example:
  #
  #   puts r.format('~', 'split')
  #
  # would print:
  #
  #   s
  #   p
  #   l
  #   i
  #   t
  #
  # whilst:
  #
  #   r.min_break= 1
  #   puts r.format('~', 'split')
  #
  # would print:
  #
  #   s-
  #   p-
  #   l-
  #   i-
  #   t
  #
  # Alternative breaking strategies can be specified using the "break"
  # option in a configuration hash. For example:
  #
  #   r.break = MyBreaker.new
  #   r.format(fmt, data)
  #
  # #format expects a user-defined line-breaking strategy to listen to the
  # method #break that takes three arguments (the string to be broken, the
  # maximum permissible length of the initial section, and the total width
  # of the field being filled). #break must return a list of two strings:
  # the initial (broken) section of the word, and the remainder of the
  # string respectivly).
  #
  # For example:
  #   class MyBreaker
  #     def break(str, initial, total)
  #       [ str[0, initial-1].'~'], str[initial-1..-1] ]
  #     end
  #   end
  #
  #   r.break = MyBreaker.new
  #
  # makes '~' the hyphenation character, whilst:
  #   class WrapAndSlop
  #     def break(str, initial, total)
  #       if (initial == total)
  #         str =~ /\A(\s*\S*)(.*)/
  #         [ $1, $2 ]
  #       else
  #         [ '', str ]
  #       end
  #     end
  #   end
  #
  #   r.break = WrapAndSlop.new
  #
  # wraps excessively long words to the next line and "slops" them over the
  # right margin if necessary.
  #
  # The Text::Reform class provides three functions to simplify the use of
  # variant hyphenation schemes. Text::Reform::break_wrap returns an
  # instance implementing the "wrap-and-slop" algorithm shown in the last
  # example, which could therefore be rewritten:
  #
  #   r.break = Text::Reform.break_wrap
  #
  # Text::Reform::break_with takes a single string argument and returns an
  # instance of a class which hyphenates by cutting off the text at the
  # right margin and appending the string argument. Hence the first of the
  # two examples could be rewritten:
  #
  #   r.break = Text::Reform.break_with('~')
  #
  # The method Text::Reform::break_at takes a single string argument and
  # returns a reference to a sub which hyphenates by breaking immediately
  # after that string. For example:
  #
  #   r.break = Text::Reform.break_at('-')
  #   r.format("[[[[[[[[[[[[[[", "The Newton-Raphson methodology")
  #
  # returns:
  #   "The Newton-
  #    Raphson
  #    methodology"
  #
  # Note that this differs from the behaviour of Text::Reform::break_with,
  # which would be:
  #
  #   r.break = Text::Reform.break_width('-')
  #   r.format("[[[[[[[[[[[[[[", "The Newton-Raphson methodology")
  #
  # returns:
  #       "The Newton-R-
  #        aphson metho-
  #        dology"
  #
  # Choosing the correct breaking strategy depends on your kind of data.
  #
  # The method Text::Reform::break_hyphen returns an instance of a class
  # which hyphenates using a Ruby hyphenator. The hyphenator must be
  # provided to the method. At the time of release, there are two
  # implementations of hyphenators available: TeX::Hyphen by Martin DeMello
  # and Austin Ziegler (a Ruby port of Jan Pazdziora's TeX::Hyphen module);
  # and Text::Hyphen by Austin Ziegler (a significant recoding of
  # TeX::Hyphen to better support non-English languages).
  #
  # For example:
  #   r.break = Text::Reform.break_hyphen
  #
  # Note that in the previous example the calls to .break_at, .break_wrap
  # and .break_hyphen produce instances of the corresponding strategy class.
  #
  # == The algorithm #format uses is:
  #
  # 1. If interleaving is specified, split the first string in the
  #    argument list into individual format lines and add a
  #    terminating newline (unless one is already present).
  #    therwise, treat the entire string as a single "line" (like
  #    /s does in regexes)
  #
  # 2. For each format line...
  #
  #    1. determine the number of fields and shift
  #       that many values off the argument list and
  #       into the filling list. If insufficient
  #       arguments are available, generate as many
  #       empty strings as are required.
  #
  #    2. generate a text line by filling each field
  #       in the format line with the initial contents
  #       of the corresponding arg in the filling list
  #       (and remove those initial contents from the arg).
  #
  #    3. replace any <,>, or ^ fields by an equivalent
  #       number of spaces. Splice out the corresponding
  #       args from the filling list.
  #
  #    4. Repeat from step 2.2 until all args in the
  #       filling list are empty.
  #
  # 3. concatenate the text lines generated in step 2
  #
  # Note that in difference to the Perl version of Text::Reform,
  # this version does not currently loop over several format strings
  # in one function call.
  #
  #
  # == Reform#format examples
  #
  # As an example of the use of #format, the following:
  #
  #   count = 1
  #   text = "A big long piece of text to be formatted exquisitely"
  #   output = ''
  #   output << r.format("       ||||  <<<<<<<<<<   ", count, text)
  #   output << r.format("       ----------------   ",
  #                       "       ^^^^  ]]]]]]]]]]|  ", count+11, text)
  #
  # results in +output+:
  #           1    A big lon-
  #           ----------------
  #           12      g piece|
  #                   of text|
  #                to be for-|
  #                matted ex-|
  #                 quisitely|
  #
  # Note that block fields in a multi-line format string,
  # cause the entire multi-line format to be repeated as
  # often as necessary.
  #
  # Unlike traditional Perl #format arguments, picture strings and
  # arguments cannot be interleaved in Ruby version. This is partly
  # by intention to see if the feature is a feature or if it
  # can be disposed with. Another example:
  #
  #   report = ''
  #   report << r.format(
  #               'Name           Rank    Serial Number',
  #               '====           ====    =============',
  #               '<<<<<<<<<<<<<  ^^^^    <<<<<<<<<<<<<',
  #               name,           rank,   serial_number
  #            )
  #
  # results in:
  #
  #   Name           Rank    Serial Number
  #   ====           ====    =============
  #   John Doe       high    314159
  #
  # == Numerical formatting
  #
  # The ">>>.<<<" and "]]].[[[" field specifiers may be used to format
  # numeric values about a fixed decimal place marker. For example:
  #
  #   puts r.format('(]]]]].[[)', %w{
  #                1
  #                1.0
  #                1.001
  #                1.009
  #                123.456
  #                1234567
  #                one two
  #   })
  #
  # would print:
  #
  #   (   1.0)
  #   (   1.0)
  #   (   1.00)
  #   (   1.01)
  #   ( 123.46)
  #   (#####.##)
  #   (?????.??)
  #   (?????.??)
  #
  # Fractions are rounded to the specified number of places after the
  # decimal, but only significant digits are shown. That's why, in the
  # above example, 1 and 1.0 are formatted as "1.0", whilst 1.001 is
  # formatted as "1.00".
  #
  # You can specify that the maximal number of decimal places always be used
  # by giving the configuration option 'numeric' the value NUMBERS_ALL_PLACES.
  # For example:
  #
  #   r.numeric = Text::Reform::NUMBERS_ALL_PLACES
  #   puts r.format('(]]]]].[[)', <<EONUMS)
  #     1
  #     1.0
  #   EONUMS
  #
  # would print:
  #
  #   (   1.00)
  #   (   1.00)
  #
  # Note that although decimal digits are rounded to fit the specified width, the
  # integral part of a number is never modified. If there are not enough places
  # before the decimal place to represent the number, the entire number is
  # replaced with hashes.
  #
  # If a non-numeric sequence is passed as data for a numeric field, it is
  # formatted as a series of question marks. This querulous behaviour can be
  # changed by giving the configuration option 'numeric' a value that
  # matches /\bSkipNaN\b/i in which case, any invalid numeric data is simply
  # ignored. For example:
  #
  #
  #   r.numeric = Text::Reform::NUMBERS_SKIP_NAN
  #   puts r.format('(]]]]].[[)', %w{
  #                1
  #                two three
  #                4
  #   })
  #
  #
  # would print:
  #
  #   (   1.0)
  #   (   4.0)
  #
  # == Filling block fields with lists of values
  #
  # If an argument contains an array, then #format
  # automatically joins the elements of the array into a single string, separating
  # each element with a newline character. As a result, a call like this:
  #
  #   svalues = %w{ 1 10 100 1000 }
  #   nvalues = [1, 10, 100, 1000]
  #   puts r.format(
  #     "(]]]].[[)",
  #     svalues                         # you could also use nvalues here.
  #  )
  #
  # will print out
  #
  #       (  1.00)
  #       ( 10.00)
  #       (100.00)
  #       (1000.00)
  #
  # as might be expected.
  #
  # Note: While String arguments are consumed during formatting process
  # and will be empty at the end of formatting, array arguments are not.
  # So svalues (nvalues) still contains [1,10,100,1000] after the call
  # to #format.
  #
  # == Headers, footers, and pages
  #
  # The #format method can also insert headers, footers, and page-feeds
  # as it formats. These features are controlled by the "header", "footer",
  # "page_feed", "page_len", and "page_num" options.
  #
  # If the +page_num+ option is set to an Integer value, page numbering
  # will start at that value.
  #
  # The +page_len+ option specifies the total number of lines in a page (including
  # headers, footers, and page-feeds).
  #
  # The +page_width+ option specifies the total number of columns in a page.
  #
  # If the +header+ option is specified with a string value, that string is
  # used as the header of every page generated. If it is specified as a block,
  # that block is called at the start of every page and
  # its return value used as the header string. When called, the block is
  # passed the current page number.
  #
  # Likewise, if the +footer+ option is specified with a string value, that
  # string is used as the footer of every page generated. If it is specified
  # as a block, that block is called at the *start*
  # of every page and its return value used as the footer string. When called,
  # the footer block is passed the current page number.
  #
  # Both the header and footer options can also be specified as hash references.
  # In this case the hash entries for keys +left+, +centre+ (or +center+), and
  # +right+ specify what is to appear on the left, centre, and right of the
  # header/footer. The entry for the key +width+ specifies how wide the
  # footer is to be. If the +width+ key is omitted, the +page_width+ configuration
  # option (which defaults to 72 characters) is used.
  #
  # The  +:left+, +:centre+, and +:right+ values may be literal
  # strings, or blocks (just as a normal header/footer specification may
  # be.) See the second example, below.
  #
  # Another alternative for header and footer options is to specify them as a
  # block that returns a hash reference. The subroutine is called for each
  # page, then the resulting hash is treated like the hashes described in the
  # preceding paragraph. See the third example, below.
  #
  # The +page_feed+ option acts in exactly the same way, to produce a
  # page_feed which is appended after the footer. But note that the page_feed
  # is not counted as part of the page length.
  #
  # All three of these page components are recomputed at the *start of each
  # new page*, before the page contents are formatted (recomputing the header
  # and footer first makes it possible to determine how many lines of data to
  # format so as to adhere to the specified page length).
  #
  # When the call to #format is complete and the data has been fully formatted,
  # the footer subroutine is called one last time, with an extra argument of +true+.
  # The string returned by this final call is used as the final footer.
  #
  # So for example, a 60-line per page report, starting at page 7,
  # with appropriate headers and footers might be set up like so:
  #
  #   small = Text::Reform.new
  #   r.header = lambda do |page| "Page #{page}\n\n" end
  #   r.footer = lambda do |page, last|
  #     if last
  #       ''
  #     else
  #       ('-'*50 + "\n" + small.format('>'*50, "...#{page+1}"))
  #     end
  #   end
  #   r.page_feed = "\n\n"
  #   r.page_len = 60
  #   r.page_num = 7
  #
  #   r.format(template, data)
  #
  # Note that you can't reuse the +r+ instance of Text::Reform inside
  # the footer, it will end up calling itself recursivly until stack
  # exhaustion.
  #
  # Alternatively, to set up headers and footers such that the running
  # head is right justified in the header and the page number is centred
  # in the footer:
  #
  #   r.header = { :right => 'Running head' }
  #   r.footer = { :centre => lambda do |page| "page #{page}" end }
  #   r.page_len = 60
  #
  #   r.format(template, data)
  #
  # The footer in the previous example could also have been specified the other
  # way around, as a block that returns a hash (rather than a hash containing
  # a block):
  #
  #   r.header = { :right => 'Running head' }
  #   r.footer = lambda do |page| { :center => "page #{page}" } end
  #
  #
  # = AUTHOR
  #
  # Original Perl library and documentation:
  # Damian Conway (damian at conway dot org)
  #
  # Translating everything to Ruby (and leaving a lot of stuff out):
  # Kaspar Schiess (eule at space dot ch)
  #
  # = BUGS
  #
  # There are undoubtedly serious bugs lurking somewhere in code this funky :-)
  # Bug reports and other feedback are most welcome.
  #
  # = COPYRIGHT
  #
  # Copyright (c) 2005, Kaspar Schiess. All Rights Reserved.
  # This module is free software. It may be used, redistributed
  # and/or modified under the terms of the Ruby License
  # (see http://www.ruby-lang.org/en/LICENSE.txt)
class Text::Reform
  VERSION = "0.2.0"

    # various regexp parts for matching patterns.
  BSPECIALS       = %w{ [ | ] }
  LSPECIALS       = %w{ < ^ > }
  LJUSTIFIED      = "[<]{2,} [>]{2,}"
  BJUSTIFIED      = "[\\[]{2,} [\\]]{2,}"
  BSINGLE         = "~+"
  SPECIALS        = [BSPECIALS, LSPECIALS].flatten.map { |spec| Regexp.escape(spec)+"{2,}" }
  FIXED_FIELDPAT  = [LJUSTIFIED, BJUSTIFIED, BSINGLE, SPECIALS ].flatten.join('|')

  DECIMAL       = '.'          # TODO: Make this locale dependent
    # Matches one or more > followed by . followed by one or more <
  LNUMERICAL    = "[>]+ (?:#{Regexp.escape(DECIMAL)}[<]{1,})"
    # Matches one or more ] followed by . followed by one or more [
  BNUMERICAL    = "[\\]]+ (?: #{Regexp.escape(DECIMAL)} [\\[]{1,})"

  FIELDPAT      = [LNUMERICAL, BNUMERICAL, FIXED_FIELDPAT].join('|')

  LFIELDMARK    = [LNUMERICAL, LJUSTIFIED, LSPECIALS.map { |l| Regexp.escape(l) + "{2}" } ].flatten.join('|')
  BFIELDMARK    = [BNUMERICAL, BJUSTIFIED, BSINGLE, BSPECIALS.map { |l| Regexp.escape(l) + "{2}" } ].flatten.join('|')

  FIELDMARK     = [LNUMERICAL, BNUMERICAL, BSINGLE, LJUSTIFIED, BJUSTIFIED, LFIELDMARK, BFIELDMARK].flatten.join('|')

    # For use with #header, #footer, and #page_feed; this will clear the
    # header, footer, or page feed block result to be an empty block.
  CLEAR_BLOCK = lambda { "" }

    # Proc returning page header. This is called before the page actually
    # gets formatted to permit calculation of page length.
    #
    # *Default*::    +CLEAR_BLOCK+
  attr_accessor :header

    # Proc returning the page footer. This gets called before the
    # page gets formatted to permit calculation of page length.
    #
    # *Default*::    +CLEAR_BLOCK+
  attr_accessor :footer

    # Proc to be called for page feed text. This is also called at
    # the start of each page, but does not count towards page length.
    #
    # *Default*::    +CLEAR_BLOCK+
  attr_accessor :page_feed

    # Specifies the total number of lines in a page (including headers,
    # footers, and page-feeds).
    #
    # *Default*::    +nil+
  attr_accessor :page_len

    # Where to start page numbering.
    #
    # *Default*::    +nil+
  attr_accessor :page_num

    # Specifies the total number of columns in a page.
    #
    # *Default*::    72
  attr_accessor :page_width

    # Break class instance that is used to break words in hyphenation. This
    # class must have a #break method accepting the three arguments +str+,
    # +initial_max_length+ and +maxLength+.
    #
    # You can directly call the break_* methods to produce such a class
    # instance for you; Available methods are #break_width, #break_at,
    # #break_wrap, #break_hyphenator.
    #
    # *Default*::    Text::Hyphen::break_with('-')
  attr_accessor :break

    # Specifies the minimal number of characters that must be left on a
    # line. This prevents breaking of words below its value.
    #
    # *Default*::    2
  attr_accessor :min_break

    # If +true+, causes any sequence of spaces and/or tabs (but not
    # newlines) in an interpolated string to be replaced with a single
    # space.
    #
    # *Default*::   +false+
  attr_accessor :squeeze

    # If +true+, causes newlines to be removed from the input. If you want
    # to squeeze all whitespace, set #fill and #squeeze to true.
    #
    # *Default*::    +false+
  attr_accessor :fill

    # Controls character that is used to fill lines that are too short.
    # If this attribute has a hash value, the symbols :left and :right
    # store the filler character to use on the left and the right,
    # respectivly.
    #
    # *Default*::   +' '+ on both sides
  attr_accessor :filler
  def filler=(value) #:nodoc:
    if value.kind_of?(Hash)
      unless value[:left] and value[:right]
        raise ArgumentError, "If #filler is provided as a Hash, it must contain the keys :left and :right"
      else
        @filler = value
      end
    else
      @filler = { :left => value, :right => value }
    end
  end

    # This implies that formats and the variables from which they're filled
    # need to be interleaved. That is, a multi-line specification like this:
    #
    #   print format(
    #   "Passed:              ##
    #      [[[[[[[[[[[[[[[     # single format specification
    #   Failed:                # (needs two sets of data)
    #      [[[[[[[[[[[[[[[",  ##
    #
    #    fails, passes)       ##  two arrays, data for previous format
    #
    # would print:
    #
    #   Passed:
    #       <pass 1>
    #   Failed:
    #      <fail 1>
    #   Passed:
    #      <pass 2>
    #   Failed:
    #      <fail 2>
    #   Passed:
    #      <pass 3>
    #   Failed:
    #      <fail 3>
    #
    # because the four-line format specifier is treated as a single unit, to
    # be repeatedly filled until all the data in +passes+ and +fails+ has
    # been consumed.
    #
    # *Default*::    false
  attr_accessor :interleave

    # Numbers are printed, leaving off unnecessary decimal places. Non-
    # numeric data is printed as a series of question marks. This is the
    # default for formatting numbers.
  NUMBERS_NORMAL             = 0
    # Numbers are printed, retaining all decimal places. Non-numeric data is
    # printed as a series of question marks.
    #
    #     [[[[[.]]       # format
    #     1.0 ->     1.00
    #     1   ->     1.00
  NUMBERS_ALL_PLACES         = 1
    # Numbers are printed as ffor +NUMBERS_NORMAL+, but NaN ("not a number")
    # values are skipped.
  NUMBERS_SKIP_NAN           = 2
    # Numbers are printed as for +NUMBERS_ALL_PLACES+, but NaN values are
    # skipped.
  NUMBERS_ALL_AND_SKIP       = NUMBERS_ALL_PLACES | NUMBERS_SKIP_NAN

    # Specifies handling method for numerical data. Allowed values include:
    # * +NUMBERS_NORMAL+
    # * +NUMBERS_ALL_PLACES+
    # * +NUMBERS_SKIP_NAN+
    # * +NUMBERS_ALL_AND_SKIP+
    #
    # *Default*::    NUMBERS_NORMAL
  attr_accessor :numeric

    # Controls trimming of whitespace at end of lines.
    #
    # *Default*::    +true+
  attr_accessor :trim

    # Create a Text::Reform object. Accepts an optional hash of
    # construction option (this will change to named parameters in Ruby
    # 2.0). After the initial object is constructed (with either the
    # provided or default values), the object will be yielded (as +self+) to
    # an optional block for further construction and operation.

  def initialize(options = {}) #:yields self:
    @debug      = options[:debug]       || false
    @header     = options[:header]      || CLEAR_BLOCK
    @footer     = options[:footer]      || CLEAR_BLOCK
    @page_feed  = options[:page_feed]   || CLEAR_BLOCK
    @page_len   = options[:page_len]    || nil
    @page_num   = options[:page_num]    || nil
    @page_width = options[:page_width]  || 72
    @break      = options[:break]       || Text::Reform.break_with('-')
    @min_break  = options[:min_break]   || 2
    @squeeze    = options[:squeeze]     || false
    @fill       = options[:fill]        || false
    @filler     = options[:filler]      || { :left => ' ', :right => ' ' }
    @interleave = options[:interleave]  || false
    @numeric    = options[:numeric]     || 0
    @trim       = options[:trim]        || false

    yield self if block_given?
  end

    # Format data according to +format+.
  def format(*args)
    @page_num ||= 1

    __debug("Acquiring header and footer: ", @page_num)
    header = __header(@page_num)
    footer = __footer(@page_num, false)

    previous_footer = footer

    line_count  = count_lines(header, footer)
    hf_count    = line_count

    text          = header
    format_stack  = []

    while (args and not args.empty?) or (not format_stack.empty?)
      __debug("Arguments: ", args)
      __debug("Formats left: ", format_stack)

      if format_stack.empty?
        if @interleave
            # split format in its parts and recombine line by line
          format_stack += args.shift.split(%r{\n}o).collect { |fmtline| fmtline << "\n" }
        else
          format_stack << args.shift
        end
      end

      format = format_stack.shift

      parts = format.split(%r{(               # Capture
                                \n          | # newline... OR
                                (?:\\.)+    | # one or more escapes... OR
                                #{FIELDPAT} | # patterns
                              )}ox)
      parts << "\n" unless parts[-1] == "\n"

          # Count all fields (inject 0, increment when field) and prepare
          # data.
      field_count = parts.inject(0) do |count, el|
        if (el =~ /#{LFIELDMARK}/ox or el =~ /#{FIELDMARK}/ox)
          count + 1
        else
          count
        end
      end

      if field_count.nonzero?
        data = args.first(field_count).collect do |el|
          if el.kind_of?(Array)
            el.join("\n")
          else
            el.to_s
          end
        end
          # shift all arguments that we have just consumed
        args = args[field_count..-1]
          # Is argument count correct ?
        data += [''] * (field_count-data.length) unless data.length == field_count
      else
        data = [[]] # one line of data, contains nothing
      end

      first_line = true
      data_left = true
      while data_left
        idx = 0
        data_left = false

        parts.each do |part|
            # Is part an escaped format literal ?
          if part =~ /\A (?:\\.)+/ox
            __debug("esc literal: ", part)
            text << part.gsub(/\\(.)/, "\1")
              # Is part a once field mark ?
          elsif part =~ /(#{LFIELDMARK})/ox
            if first_line
              type = __construct_type($1, LJUSTIFIED)

              __debug("once field: ", part)
              __debug("data is: ", data[idx])
              text << replace(type, part.length, data[idx])
              __debug("data now: ", data[idx])
            else
              text << (@filler[:left] * part.length)[0, part.length]
              __debug("missing once field: ", part)
            end
            idx += 1
              # Is part a multi field mark ?
          elsif part =~ /(#{FIELDMARK})/ox and part[0, 2] != '~~'
            type = __construct_type($1, BJUSTIFIED)

            __debug("multi field: ", part)
            __debug("data is: ", data[idx])
            text << replace(type, part.length, data[idx])
            __debug("data now: ", data[idx])
            data_left = true if data[idx].strip.length > 0
            idx += 1
              # Part is a literal.
          else
            __debug("literal: ", part)
            text << part.gsub(/\0(\0*)/, '\1')  # XXX: What is this gsub for ?

              # New line ?
            if part == "\n"
              line_count += 1
              if @page_len && line_count >= @page_len
                __debug("\tejecting page: #@page_num")

                @page_num += 1
                page_feed = __pagefeed
                header = __header(@page_num)

                text << footer + page_feed + header
                previous_footer = footer

                footer = __footer(@page_num, false)

                line_count = hf_count = (header.count("\n") + footer.count("\n"))

                header = page_feed + header
              end
            end
          end  # multiway if on part
        end # parts.each

        __debug("Accumulated: ", text)

        first_line = false
      end
    end  # while args or formats left

      # Adjust final page header or footer as required
    if hf_count > 0 and line_count == hf_count
        # there is a header that we don't need
      text.sub!(/#{Regexp.escape(header)}\Z/, '')
    elsif line_count > 0 and @page_len and @page_len > 0
        # missing footer:
      text << "\n" * (@page_len - line_count) + footer
      previous_footer = footer
    end

      # Replace last footer
    if previous_footer and not previous_footer.empty?
      lastFooter = __footer(@page_num, true)
      footerDiff = lastFooter.count("\n") - previous_footer.count("\n")

        # Enough space to squeeze the longer final footer in ?
      if footerDiff > 0 && text =~ /(#{'^[^\S\n]*\n' * footerDiff}#{Regexp.escape(previous_footer)})\Z/
        previous_footer = $1
        footerDiff = 0
      end

        # If not, create an empty page for it.
      if footerDiff > 0
        @page_num += 1
        lastHeader = __header(@page_num)
        lastFooter = __footer(@page_num, true)

        text << lastHeader
        text << "\n" * (@page_len - lastHeader.count("\n") - lastFooter.count("\n"))
        text << lastFooter
      else
        lastFooter = "\n" * (-footerDiff) + lastFooter
        text[-(previous_footer.length), text.length] = lastFooter
      end
    end

      # Trim text
    text.gsub!(/[ ]+$/m, '') if @trim
    text
  end

    # Replaces a placeholder with the text given. The +format+ string gives
    # the type of the replace match: When exactly two chars, this indicates
    # a text replace field, when longer, this is a numeric field.
  def replace(format, length, value)
    text      = ''
    remaining = length
    filled    = 0

    __debug("value is: ", value)

    if @fill
      value.sub!(/\A\s*/m, '')
    else
      value.sub!(/\A[ \t]*/, '')
    end

    if value and format.length > 2
        # find length of numerical fields
      if format =~ /([\]>]+)#{Regexp.escape(DECIMAL)}([\[<]+)/
        ilen, dlen = $1.length, $2.length
      end

        # Try to extract a numeric value from +value+
      done = false
      while not done
        num, extra = scanf_remains(value, "%f")
        __debug "Number split into: ", [num, extra]
        done = true

        if extra.length == value.length
          value.sub!(/\s*\S*/, '')  # skip offending non number value
          if (@numeric & NUMBERS_SKIP_NAN) > 0 && value =~ /\S/
            __debug("Not a Number, retrying ", value)
            done = false
          else
            text = '?' * ilen + DECIMAL + '?' * dlen
            return text
          end
        end
      end

      __debug("Finally number is: ", num)

      formatted = "%#{format.length}.#{dlen}f"% num
      if formatted.length > format.length
        text = '#' * ilen + DECIMAL + '#'*dlen
      else
        text = formatted
      end

        # Only output significant digits. Unless not all places were
        # explicitly requested or the number has more digits than we just
        # output replace trailing zeros with spaces.
      unless (@numeric & NUMBERS_ALL_PLACES > 0) or num.to_s =~ /#{Regexp.escape(DECIMAL)}\d\d{#{dlen},}$/
        text.sub!(/(#{Regexp.escape(DECIMAL)}\d+?)(0+)$/) do |match|
          $1 + ' '*$2.length
        end
      end

      value.replace(extra)
      remaining = 0
    else
      while not (value =~ /\S/o).nil?
          # Only whitespace remaining ?
        if ! @fill && value.sub!(/\A[ \t]*\n/, '')
          filled = 2
          break
        end
        break unless value =~ /\A(\s*)(\S+)(.*)\z/om;

        ws, word, extra = $1, $2, $3

          # Replace all newlines by spaces when fill was specified.
        nonnl = (ws =~ /[^\n]/o)
        if @fill
          ws.gsub!(/\n/) do |match|
            nonnl ? '' : ' '
          end
        end

          # Replace all whitespace by one space if squeeze was specified.
        lead = @squeeze ? (ws.length > 0 ? ' ' : '') : ws
        match = lead + word

        __debug("Extracted: ", match)
        break if text and match =~ /\n/o

        if match.length <= remaining
          __debug("Accepted: ", match)
          text << match
          remaining -= match.length
          value.replace(extra)
        else
          __debug("Need to break: ", match)
          if (remaining - lead.length) >= @min_break
            __debug("Trying to break: ", match)
            broken, left = @break.break(match, remaining, length)
            text << broken
            __debug("Broke as: ", [broken, left])
            value.replace left + extra

              # Adjust remaining chars, but allow for underflow.
            t = remaining-broken.length
            if t < 0
              remaining = 0
            else
              remaining = t
            end
          end
          break
        end

        filled = 1
      end
    end

    if filled.zero? and remaining > 0 and value =~ /\S/ and text.empty?
      value.sub!(/^\s*(.{1,#{remaining}})/, '')
      text = $1
      remaining -= text.length
    end

      # Justify format?
    if text =~ / /o and format == 'J' and value =~ /\S/o and filled != 2
        # Fully justified
      text.reverse!
      text.gsub!(/( +)/o) do |match|
        remaining -= 1
        if remaining > 0
          " #{$1}"
        else
          $1
        end
      end while remaining > 0
      text.reverse!
    elsif format =~ /\>|\]/o
        # Right justified
      text[0, 0] = (@filler[:left] * remaining)[0, remaining] if remaining > 0
    elsif format =~ /\^|\|/o
        # Center justified
      half_remaining = remaining / 2
      text[0, 0] = (@filler[:left] * half_remaining)[0, half_remaining]
      half_remaining = remaining - half_remaining
      text << (@filler[:right] * half_remaining)[0, half_remaining]
    else
        # Left justified
      text << (@filler[:right] * remaining)[0, remaining]
    end

    text
  end

    # Quotes any characters that might be interpreted in +str+ to be normal
    # characters.
  def quote(str)
    puts 'Text::Reform warning: not quoting string...' if @debug
    str
  end

    # Turn on internal debugging output for the duration of the
    # block.
  def debug
    d = @debug
    @debug = true
    yield
    @debug = d
  end

  class << self
      # Takes a +hyphen+ string as argument, breaks by inserting that hyphen
      # into the word to be hyphenated.
    def break_with(hyphen)
      BreakWith.new(hyphen)
    end

      # Takes a +bat+ string as argument, breaks by looking for that
      # substring and breaking just after it.
    def break_at(bat)
      BreakAt.new(bat)
    end

      # Breaks by using a 'wrap and slop' algorithm.
    def break_wrap
      BreakWrap.new
    end

      # Hyphenates with a class that implements the API of TeX::Hyphen or
      # Text::Hyphen.
    def break_hyphenator(hyphenator)
      BreakHyphenator.new(hyphenator)
    end
  end

    # Return the header to use. Header can be in many formats, refer
    # yourself to the documentation.
  def __header(page_num)
    __header_or_footer(@header, page_num, false)
  end
  private :__header

    # Return the footer to use for +page_num+ page. +last+ is true if this
    # is the last page.
  def __footer(page_num, last)
    __header_or_footer(@footer, page_num, last)
  end
  private :__footer

    # Return a header or footer, disambiguating of types and unchomping is
    # done here.
    #
    #
    # +element+ is the element (header or footer) to process.
    # +page+ is the current page number. +last+ indicates
    # whether this is the last page.
  def __header_or_footer(element, page, last)
    __debug("element: ", element)
    if element.respond_to?(:call)
      if element.arity == 1
        __header_or_footer(element.call(page), page, last)
      else
        __header_or_footer(element.call(page, last), page, last)
      end
    elsif element.kind_of?(Hash)
      page_width = element[:width] || @page_width
      @internal_formatter = self.class.new unless @internal_formatter

      if element[:left]
        format  = "<" * page_width
        data    = element[:left]
      end

      if element[:center] or element[:centre]
        format  = "^" * page_width
        data    = element[:center] || element[:centre]
      end

      if element[:right]
        format  = ">" * page_width
        data    = element[:right]
      end

      if format
        if data.respond_to?(:call)
          @internal_formatter.format(format, __header_or_footer(data.call(page), page, last))
        else
          @internal_formatter.format(format, data.dup)
        end
      else
        ""
      end
    else
      unchomp(element)
    end
  end
  private :__header_or_footer

    # Use the page_feed attribute to get the page feed text. +page_feed+ can
    # contain a block to call or a String.
  def __pagefeed
    if @page_feed.respond_to?(:call)
      @page_feed.call(@page)
    else
      @page_feed
    end
  end
  private :__pagefeed

    # Using Scanf module, scanf a string and return what has not been
    # matched in addition to normal scanf return.
  def scanf_remains(value, fstr, &block)
    if block.nil?
      unless fstr.kind_of?(Scanf::FormatString)
        fstr = Scanf::FormatString.new(fstr)
      end
      [ fstr.match(value), fstr.string_left ]
    else
      value.block_scanf(fstr, &block)
    end
  end

    # Count occurrences of \n (lines) of all strings that are passed as
    # parameter.
  def count_lines(*args)
    args.inject(0) do |sum, el|
      sum + el.count("\n")
    end
  end

    # Construct a type that can be passed to #replace from last a string.
  def __construct_type(str, justifiedPattern)
    if str =~ /#{justifiedPattern}/x
      'J'
    else
      str
    end
  end

    # Adds a \n character to the end of the line unless it already has a
    # \n at the end of the line. Returns a modified copy of +str+.
  def unchomp(str)
    unchomp!(str.dup)
  end

    # Adds a \n character to the end of the line unless it already has a
    # \n at the end of the line.
  def unchomp!(str)
    if str.empty? or str[-1] == ?\n
      str
    else
      str << "\n"
    end
  end

    # Debug output. Message +msg+ is printed at start of line, then +obj+
    # is output using +pp+.
  def __debug(msg, obj = nil)
    return unless @debug
    require 'pp'
    print msg
    pp obj
  end
  private :__debug

  class BreakWith
    def initialize hyphen
      @hyphen = hyphen
      @hylen = hyphen.length
    end

      # Break by inserting a hyphen string.
      #
      # +initial_max_length+::  The maximum size of the first part of the
      #                         word that will remain on the first line.
      # +total_width+::         The total width that can be appended to this
      #                         first line.
    def break(str, initial_max_length, total_width)
      if total_width <= @hylen
        ret = [str[0...1], str[1..-1]]
      else
        ret = [str[0...(initial_max_length-@hylen)], str[(initial_max_length-@hylen)..-1]]
      end

      if ret.first =~ /\A\s*\Z/
        return ['', str]
      else
        return [ret.first + @hyphen, ret.last]
      end
    end
  end

  class BreakAt
    def initialize hyphen
      @hyphen = hyphen
    end

      # Break by inserting a hyphen string.
      #
      # +initial_max_length+::  The maximum size of the first part of the
      #                         word that will remain on the first line.
      # +total_width+::         The total width that can be appended to this
      #                         first line.
    def break(str, initial_max_length, total_width)
      max = total_width - @hyphen.length
      if max <= 0
        ret = [str[0, 1], str[1, -1]]
      elsif str =~ /(.{1,#{max}}#@hyphen)(.*)/s
        ret = [ $1, $2 ]
      elsif str.length > total_width
        sep = initial_max_length-@hyphen.length
        ret = [
          str[0, sep]+@hyphen,
          str[sep..-1]
        ]
      else
        ret = [ '', str ]
      end

      return '', str if ret[0] =~ /\A\s*\Z/
      return ret
    end
  end

  class BreakWrap
    def initialize
    end

      # Break by wrapping and slopping to the next line.
      #
      # +initial_max_length+::  The maximum size of the first part of the
      #                         word that will remain on the first line.
      # +total_width+::         The total width that can be appended to this
      #                         first line.
    def break(text, initial, total)
      if initial == total
        text =~ /\A(\s*\S*)(.*)/
        return $1, $2
      else
        return '', text
      end
    end
  end

    # This word-breaker uses a class that implements the API presented by
    # TeX::Hyphen and Text::Hyphen modules.
  class BreakHyphenator
    def initialize(hyphenator)
      @hyphenator = hyphenator
    end

      # Break a word using the provided hyphenation module that responds to
      # #hyphenate_to.
      #
      # +initial_max_length+::  The maximum size of the first part of the
      #                         word that will remain on the first line.
      # +total_width+::         The total width that can be appended to this
      #                         first line.
    def break(str, initial_max_length, total_width)
      res = @hyphenator.hyphenate_to(str, initial_max_length)
      res.map! { |ee| ee.nil? ? "" : ee }
      res
    end
  end
end
