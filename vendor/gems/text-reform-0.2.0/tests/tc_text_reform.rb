$LOAD_PATH.unshift "../lib" if __FILE__ == $0

require 'test/unit'
require 'text/reform'

class Test__Text_Reform < Test::Unit::TestCase
  TEST_PAGINATION_1 = <<-EOS
Page 7

Vestibulum at felis. Praesent turpis
velit, elementum eget, porttitor id,
bibendum auctor, metus. Ut facilisis
commodo quam. Quisque nec urna ultr-
icies justo condimentum tristique.  
Proin eget sem eu neque sollicitudin
--------------------------------------------------
                                              ...8


Page 8

luctus. Etiam mi dolor, aliquet ege-
t, pellentesque ultrices, nonummy e-
t, diam. Sed odio enim, ultrices no-
n, aliquam vitae, sodales sed, odio.
Maecenas id justo. Quisque viverra  
malesuada neque. Cras auctor ipsum  
--------------------------------------------------
                                              ...9


Page 9

ac ante. Vestibulum consectetuer. N-
ullam mi est, pretium at, elementum 
at, dictum scelerisque, purus. Inte-
ger leo velit, adipiscing in, biben-
dum nec, euismod sit amet, quam. Sed
porttitor lorem vitae neque. Maecen-
--------------------------------------------------
                                             ...10


Page 10

as sem lorem, aliquet non, vulputate
vitae, consequat ornare, elit. Pell-
entesque nec lectus quis felis posu-
ere pharetra.                       




EOS
  TEST_PAGINATION_2 = <<-EOS
                                                            Running head
Vestibulum at felis. Praesent turpis
velit, elementum eget, porttitor id,
bibendum auctor, metus. Ut facilisis
commodo quam. Quisque nec urna ultr-
icies justo condimentum tristique.  
Proin eget sem eu neque sollicitudin
luctus. Etiam mi dolor, aliquet ege-
t, pellentesque ultrices, nonummy e-
                                 page 1                                 


                                                            Running head
t, diam. Sed odio enim, ultrices no-
n, aliquam vitae, sodales sed, odio.
Maecenas id justo. Quisque viverra  
malesuada neque. Cras auctor ipsum  
ac ante. Vestibulum consectetuer. N-
ullam mi est, pretium at, elementum 
at, dictum scelerisque, purus. Inte-
ger leo velit, adipiscing in, biben-
                                 page 2                                 


                                                            Running head
dum nec, euismod sit amet, quam. Sed
porttitor lorem vitae neque. Maecen-
as sem lorem, aliquet non, vulputate
vitae, consequat ornare, elit. Pell-
entesque nec lectus quis felis posu-
ere pharetra.                       


                                 page 3                                 
EOS

  attr_reader :r
  def setup
    @r = Text::Reform.new
  end

  def test_abiglongtext
    count = 1
    text = "A big long piece of text to be formatted exquisitely"
    output = ""
    output << r.format("       ||||  <<<<<<<<<<   ", count, text)
    output << r.format("       ----------------   ",
                       "       ^^^^  ]]]]]]]]]]|  ", count + 11, text)

    reference = <<-EOS
        1    A big long   
       ----------------   
        12     piece of|  
             text to be|  
              formatted|  
             exquisite-|  
                     ly|  
EOS

    assert_equal reference, output
  end

  def test_formular
    name = 'John Doe'
    rank = 'high'
    serial_number = '314159'

    report = ''
    report << r.format('Name           Rank    Serial Number',
                       '====           ====    =============',
                       '<<<<<<<<<<<<<  ^^^^    <<<<<<<<<<<<<',
                       name,           rank,   serial_number)

    result = ''
    result << "Name           Rank    Serial Number\n"
    result << "====           ====    =============\n"
    result << "John Doe       high    314159       \n"
    assert_equal result, report
  end

  def test_trim
    r.trim = false
    assert_equal 11, r.format("[[[[[[[[[[", "short").length

    r.trim = true
    assert_equal 6, r.format("[[[[[[[[[[[", "short").length
  end

  def test_filler
    r.filler = '*'
    assert_equal "Pay bearer: *******$123.4*******\n", r.format("Pay bearer: ^^^^^^^^^^^^^^^^^^^^", '$123.4')

    r.filler= '-->'
    assert_equal "Pay bearer: -->-->-$123.4-->-->-\n", r.format("Pay bearer: ^^^^^^^^^^^^^^^^^^^^", '$123.4')
    assert_equal "Pay bearer: -->-->-$12.4-->-->--\n", r.format("Pay bearer: ^^^^^^^^^^^^^^^^^^^^", '$12.4')
    assert_equal "Pay bearer: -->-->--$1.4-->-->--\n", r.format("Pay bearer: ^^^^^^^^^^^^^^^^^^^^", '$1.4')

    r.filler = {
      :left => 'l',
      :right => 'r'
    }
    assert_equal "Pay bearer: lllllll$123.4rrrrrrr\n", r.format("Pay bearer: ^^^^^^^^^^^^^^^^^^^^", '$123.4')
  end

  def test_data_format
    # String form
    s1 = r.format "]]]].[[", "1234\n123"

    # Array form
    s2 = r.format "]]]].[[", [ 1234, 123 ]

    # Array with another type
    s3 = r.format "]]]].[[", [ 1234.0, 123.0 ]

    assert_equal "1234.0 \n 123.0 \n", s1
    assert_equal s1, s2
    assert_equal s2, s3
  end

  def test_multiline_numbers
    assert_equal "1     \n2     \n3     \n", r.format("[[[[[[", (1..3).to_a.map { |el| el.to_s })
  end

  def test_wrong_number_of_data_args
    assert_nothing_raised do
      r.format("]]]]]]]] ]]]]]]]]", 'a single data item')
    end
  end

  def test_whitespace
    assert_equal("EG> h  e\t l lo           \nEG> world                \n",
                 r.format("EG> [[[[[[[[[[[[[[[[[[[[[",
                          "h  e\t l lo\nworld\t\t\t\t\t"))

    r.squeeze = true
    assert_equal("EG> h e l lo             \nEG> world                \n",
                 r.format("EG> [[[[[[[[[[[[[[[[[[[[[",
                          "h  e\t l lo\nworld\t\t\t\t\t"))

    r.fill = true
    assert_equal("EG> h e l lo world       \n",
                 r.format("EG> [[[[[[[[[[[[[[[[[[[[[",
                          "h \n e\t l\n lo\nworld\t\n\t\t\t\t"))
    r.squeeze = false
    r.fill = false
  end

  def test_format_numbers
    numbers = [ 1, 1.2, 1.23, 1.234, 1.2345, "1.2345" ]

    assert_equal("   1.0   \n   1.2   \n   1.23  \n   1.234 \n   1.234 \n   1.234 \n",
                 r.format(" ]]].[[[ ", numbers))
    assert_equal("   1.0   \n", r.format(" >>>.<<< ", numbers))
  end

  def test_basic_formatting_tests
    assert_equal " test               \n", r.format(" <<<<<<<<<<<<<<<<<< ", 'test')
    assert_equal "               test \n", r.format(" >>>>>>>>>>>>>>>>>> ", 'test')
    assert_equal " this is a test     \n", r.format(" <<<<<<<<<>>>>>>>>> ", 'this is a test')
    assert_equal "        test        \n", r.format(" ^^^^^^^^^^^^^^^^^^ ", 'test')
  end

  def test_multi_formatting_tests
    text = "A big long piece of text to be formatted exquisitely"
    assert_equal " A big long piece   \n of text to be for- \n matted exquisitely \n",
      r.format(" [[[[[[[[[[[[[[[[[[ ", text.dup)
    assert_equal "   A big long piece \n of text to be for- \n matted exquisitely \n",
      r.format(" ]]]]]]]]]]]]]]]]]] ", text.dup)
    assert_equal " A big long  piece \n of text to be for- \n matted exquisitely \n",
      r.format(" [[[[[[[[[[[]]]]]]] ", text.dup)
    assert_equal "  A big long piece  \n of text to be for- \n matted exquisitely \n",
      r.format(" |||||||||||||||||| ", text.dup)
  end

  def test_array_argument
    assert_equal " a lotta words come \n", r.format(" <<<<<<<<<<<<<<<<<< ", %w{ a lotta words come here in an array }.join(' '))
  end

   def test_break_at
    text = "supercalifragilousexpalidoucious"

    @r.break = Text::Reform.break_at('-')

    assert_equal(" supercalifragilo- \n usexpalidoucious  \n", r.format(" [[[[[[[[[[[[[[[[[ ", text.dup))
    assert_equal(" supercalifragilo- \n  usexpalidoucious \n", r.format(" ]]]]]]]]]]]]]]]]] ", text.dup))
    assert_equal(" supercalifragilo- \n usexpalidoucious  \n", r.format(" [[[[[[[[[[[]]]]]] ", text.dup))
    assert_equal(" supercalifragilo- \n usexpalidoucious  \n", r.format(" ||||||||||||||||| ", text.dup))
  end

  def test_break_tex
    begin
      require 'tex/hyphen'
      hy = TeX::Hyphen.new
    rescue LoadError
      begin
        require 'rubygems'
        require 'tex/hyphen'
        hy = TeX::Hyphen.new
      rescue LoadError
        print 'S'
        return true
      end
    end

    text = "supercalifragilousexpalidoucious"

    @r.break = Text::Reform.break_hyphenator(hy)

    assert_equal(" supercalifrag-    \n ilousexpali-      \n doucious          \n", r.format(" [[[[[[[[[[[[[[[[[ ", text.dup))
    assert_equal("    supercalifrag- \n      ilousexpali- \n          doucious \n", r.format(" ]]]]]]]]]]]]]]]]] ", text.dup))
    assert_equal(" supercalifrag-    \n ilousexpali-      \n doucious          \n", r.format(" [[[[[[[[[[[]]]]]] ", text.dup))
    assert_equal("  supercalifrag-   \n   ilousexpali-    \n     doucious      \n", r.format(" ||||||||||||||||| ", text.dup))
  end

  def test_break_texthyphen
    begin
      require 'text/hyphen'
      hy = Text::Hyphen.new
    rescue LoadError
      begin
        require 'rubygems'
        require 'text/hyphen'
        hy = Text::Hyphen.new
      rescue LoadError
        print 'S'
        return true
      end
    end
    text = "supercalifragilousexpalidoucious"

    hy = Text::Hyphen.new
    @r.break = Text::Reform.break_hyphenator(hy)

    assert_equal(" supercalifrag-    \n ilousexpali-      \n doucious          \n", r.format(" [[[[[[[[[[[[[[[[[ ", text.dup))
    assert_equal("    supercalifrag- \n      ilousexpali- \n          doucious \n", r.format(" ]]]]]]]]]]]]]]]]] ", text.dup))
    assert_equal(" supercalifrag-    \n ilousexpali-      \n doucious          \n", r.format(" [[[[[[[[[[[]]]]]] ", text.dup))
    assert_equal("  supercalifrag-   \n   ilousexpali-    \n     doucious      \n", r.format(" ||||||||||||||||| ", text.dup))
  end

  def test_interleave
    passes = %w{ pass_1 pass_2 pass_3 }
    fails  = %w{ fail_1 fail_2 fail_3 }

    r.interleave = true

    fmt =   "Passed:\n"
    fmt <<  "  [[[[[[[[[[[[[[[\n"
    fmt <<  "Failed:\n"
    fmt <<  "  [[[[[[[[[[[[[[[\n"

    str = r.format(fmt, passes, fails)

    assert_equal "Passed:\n  pass_1         \n  pass_2         \n  pass_3         \nFailed:\n  fail_1         \n  fail_2         \n  fail_3         \n", str
  end

  def test_hyphenate_small
    data = 'split'
    s = r.format('~', data)

    assert_equal "s\np\nl\ni\nt\n", s
    assert_equal 0, data.length

    data = 'split'
    r.min_break = 1
    s = r.format('~', data)

    assert_equal "s-\np-\nl-\ni-\nt\n", s
    assert_equal 0, data.length
  end

  class WrapAndSlop
    def break str, initial, total
      if initial==total
        str =~ /\A(\s*\S*)(.*)/
        return $1, $2
      else
        return '', str
      end
    end
  end

  def test_wrap_and_slop
    r.break = Text::Reform.break_wrap
    data = 'a looooooong word that should be wrapped and slopped'
    assert_equal("a        \nlooooooong\nword that\nshould be\nwrapped  \nand      \nslopped  \n",
                 r.format('[[[[[[[[[', data))

    r.break = WrapAndSlop.new

    data = 'a looooooong word that should be wrapped and slopped'
    assert_equal("a        \nlooooooong\nword that\nshould be\nwrapped  \nand      \nslopped  \n",
                 r.format('[[[[[[[[[', data))
  end

  def test_break_at_doku
    r.break= Text::Reform.break_at('-')
    s = r.format("[[[[[[[[[[[[[[", "The Newton-Raphson methodology")

    assert_equal("The Newton-   \nRaphson       \nmethodology   \n", s)

    r.break= Text::Reform.break_with('-')
    s = r.format("[[[[[[[[[[[[[[", "The Newton-Raphson methodology")

    assert_equal("The Newton-Ra-\nphson methodo-\nlogy          \n", s)
  end

  def test_number_formatting
    s= r.format('(]]]]].[[)', %w{1 1.0 1.001 1.009 123.456 1234567 one two})

    assert_equal("(    1.0 )\n(    1.0 )\n(    1.00)\n(    1.01)\n(  123.46)\n(#####.##)\n(?????.??)\n(?????.??)\n", s)
  end

  def test_num_all_places
    r.numeric = Text::Reform::NUMBERS_ALL_PLACES
    s = r.format('(]]]]].[[)', %w{1 1.0})
    assert_equal("(    1.00)\n(    1.00)\n", s)
  end

  def test_skip_nan
    r.numeric = Text::Reform::NUMBERS_SKIP_NAN
    s= r.format('(]]]]].[[)', %w{1 two three 4}) 
    assert_equal("(    1.0 )\n(    4.0 )\n", s)
  end

  def test_array
    nvalues = [1, 10, 100, 1000]
    svalues = %w{ 1 10 100 1000 }

    assert_equal("(   1.0 )\n(  10.0 )\n( 100.0 )\n(1000.0 )\n", r.format("(]]]].[[)", nvalues))
    assert_equal("(   1.0 )\n(  10.0 )\n( 100.0 )\n(1000.0 )\n", r.format("(]]]].[[)", svalues))
  end

  def test_pagination
    small = Text::Reform.new
    template = '[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[['
    data = <<DOLOR
Vestibulum at felis. Praesent turpis velit, elementum eget, porttitor id, bibendum auctor, metus. Ut facilisis commodo quam. Quisque nec urna ultricies justo condimentum tristique. Proin eget sem eu neque sollicitudin luctus. Etiam mi dolor, aliquet eget, pellentesque ultrices, nonummy et, diam. Sed odio enim, ultrices non, aliquam vitae, sodales sed, odio. Maecenas id justo. Quisque viverra malesuada neque. Cras auctor ipsum ac ante. Vestibulum consectetuer. Nullam mi est, pretium at, elementum at, dictum scelerisque, purus. Integer leo velit, adipiscing in, bibendum nec, euismod sit amet, quam. Sed porttitor lorem vitae neque. Maecenas sem lorem, aliquet non, vulputate vitae, consequat ornare, elit. Pellentesque nec lectus quis felis posuere pharetra.
DOLOR
    r.header = lambda do |page| "Page #{page}\n\n" end
    r.footer = lambda do |page, last|
      if last
        ''
      else
        ('-'*50 + "\n" + small.format('>'*50, "...#{page+1}"))
      end
    end
    r.page_feed = "\n\n"
    r.page_len = 10
    r.page_num = 7

    s = r.format(template, data.dup)
    assert_equal(TEST_PAGINATION_1, s)

    r.page_num = 1
    r.header = { :right => 'Running head' }
    r.footer = { :centre => lambda { |page| "page #{page}" } }
    r.page_len = 10

    assert_equal(TEST_PAGINATION_2, r.format(template, data.dup))

    r.page_num = 1
    r.header = { :right => 'Running head' }
    r.footer = lambda do |page| { :center => "page #{page}" } end

    assert_equal(TEST_PAGINATION_2, r.format(template, data.dup))
  end

  def test_page_width

    r.page_width = 30
    r.header = { :right => 'test' }
    text = 'text'

    assert_equal "                          test\ntext                       \n", 
      r.format( '[[[[[[[[[[[[[[[[[[[[[[[[[[[', text )
  end

  def test_cols
    name =  %w{Tom Dick Harry}
    score = %w{ 88   54    99}
    time  = %w{ 15   13    18}

    result =  "-------------------------------\n"
    result << "Name             Score     Time\n"
    result << "-------------------------------\n"
    result << "Tom               88        15 \n"
    result << "Dick              54        13 \n"
    result << "Harry             99        18 \n"

    assert_equal(result, r.format('-------------------------------',
                                  'Name             Score     Time',
                                  '-------------------------------',
                                  '[[[[[[[[[[[[[[   |||||     ||||',
                                  name,             score,    time))
  end
end
