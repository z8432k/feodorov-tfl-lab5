require 'fiber'

class String
  def repeat(n)
    n.times.collect{ self }.join('')
  end
end

class Parser
  class Stack < Array
    def push(a)
      if (a.kind_of? Array)
        a.reverse.each { |e| push(e) }
      else
        super(a)
      end
    end

    def replace(a)
      pop
      push a
    end
  end

  def initialize()
    @stack = Stack.new.push(:S)

    @table = {
      S: {
        'ab' => :r1,
        'ac' => :r1,
        'b' => :r2,
        'c' => :r2
      },
      A: {
        'ab' => :r3,
        'ac' => :r4
      },
      B: {
        'b' => :r5,
        :EOF => :r6
      },
      D: {
        'b' => :r8,
        'c' => :r7
      }
    }

    @rules = {
      r1: [:A],
      r2: [:D],
      r3: ['ab', :B],
      r4: ['ac', :B],
      r5: ['b', :B],
      r6: [:EOF],
      r7: ['c', :D],
      r8: ['b']
    }
  end

  def parse(fiber)
    while (fiber.alive?) do
      token = fiber.resume
      break unless token
      pass(token)
    end
    ok
  end

  private

  def pass(term, depth = 0)
    if @stack.empty?
      if term == :EOF
        return
      else
        error("Unexpected term [#{term}], expected [EOF]")
      end
    end

    if @stack.last == term
      pop
      return
    end

    if @stack.last.kind_of? Symbol
      rule(term, depth)
    else
      raise "Bad stack head [#{@stach.last}], term is [#{term}]."
    end
  end

  def ok
    puts "OK.\n\n"
  end

  def error(msg)
    raise "Parse error: #{msg}"
  end

  def pop
    @stack.pop
  end

  def push(a)
    a.reverse.each { |e| @stack.push(e) }
  end

  def replace(a)
    pop
    push a
  end

  def rule(term, depth)
    rule = @table[@stack.last][term]
    error("Unexpected term [#{term}]. Expected: [#{@table[@stack.last].keys.join(', ')}]") unless rule

    raise "Unknown parser rule [#{rule}]" unless @rules.has_key? rule
    puts "#{"\t".repeat(depth)}Pass rule [#{rule}] for [#{term}] term"

    replace(@rules[rule])
    pass(term, depth + 1)
  end
end

chain = Fiber.new do
  Fiber.yield "b"
  Fiber.yield :EOF
end

Parser.new().parse(chain)

chain = Fiber.new do
  Fiber.yield "ac"
  Fiber.yield "b"
  Fiber.yield "b"
  Fiber.yield "b"
  Fiber.yield :EOF
end

Parser.new().parse(chain)

chain = Fiber.new do
  Fiber.yield "c"
  Fiber.yield "c"
  Fiber.yield "c"
  Fiber.yield "b"
  Fiber.yield :EOF
end

Parser.new().parse(chain)

chain = Fiber.new do
  Fiber.yield "c"
  Fiber.yield "c"
  Fiber.yield "c"
  Fiber.yield "ab"
  Fiber.yield :EOF
end

Parser.new().parse(chain)
