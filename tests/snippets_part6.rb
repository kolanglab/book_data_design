# values.md: NaN boxing
QNAN = 0x7ff8_0000_0000_0000
TAGS = { int: 1, ptr: 2 }

def box_double(f) = [f].pack("D").unpack1("Q")
def box_int(i)    = QNAN | (TAGS[:int] << 48) | (i & 0xffff_ffff)
def box_ptr(a)    = QNAN | (TAGS[:ptr] << 48) | a

def kind(v)
  return :double if (v & QNAN) != QNAN
  case (v >> 48) & 0x3
  when TAGS[:int] then :int
  when TAGS[:ptr] then :ptr
  else :double
  end
end

def unbox_double(v) = [v].pack("Q").unpack1("D")
def unbox_int(v)    = (i = v & 0xffff_ffff) >= 1 << 31 ? i - (1 << 32) : i

[3.14, -0.0, 1.0 / 0.0, -2.5e300, 0.0].each do |f|
  v = box_double(f)
  raise "double #{f}" unless kind(v) == :double
  u = unbox_double(v)
  raise unless u == f || (u.to_s == f.to_s)
end
nan = box_double(0.0 / 0.0)
raise unless kind(nan) == :double && unbox_double(nan).nan?
[0, 1, -1, -42, 2**31 - 1, -2**31].each do |i|
  v = box_int(i)
  raise "int #{i}" unless kind(v) == :int && unbox_int(v) == i
end
ptr = box_ptr(0x0000_7f12_3456_7890)
raise unless kind(ptr) == :ptr && (ptr & 0xffff_ffff_ffff) == 0x7f12_3456_7890

# jit.md: quickening toy
def execute(code, stack)
  pc = 0
  while (insn = code[pc])
    case insn[0]
    when :push then stack << insn[1]
    when :add
      b, a = stack.pop, stack.pop
      code[pc] = [:add_int] if a.is_a?(Integer) && b.is_a?(Integer)
      stack << a + b
    when :add_int
      b, a = stack.pop, stack.pop
      code[pc] = [:add] unless a.is_a?(Integer) && b.is_a?(Integer)
      stack << a + b
    end
    pc += 1
  end
  stack.pop
end

code = [[:push, 1], [:push, 2], [:add]]
raise unless execute(code, []) == 3
raise unless code[2] == [:add_int]
raise unless execute(code, []) == 3            # runs the specialized path
code2 = [[:push, "a"], [:push, "b"], [:add_int]]
raise unless execute(code2, []) == "ab"        # deopt: falls back safely
raise unless code2[2] == [:add]

# concurrency.md: Channel
class Channel
  def initialize(cap)
    @buf, @cap = [], cap
    @mu = Mutex.new
    @senders   = ConditionVariable.new
    @receivers = ConditionVariable.new
  end

  def send(v)
    @mu.synchronize do
      @senders.wait(@mu) while @buf.size == @cap
      @buf << v
      @receivers.signal
    end
  end

  def receive
    @mu.synchronize do
      @receivers.wait(@mu) while @buf.empty?
      v = @buf.shift
      @senders.signal
      v
    end
  end
end

ch = Channel.new(3)
producer = Thread.new { 100.times { |i| ch.send(i) }; ch.send(:done) }
sum = 0
while (v = ch.receive) != :done
  sum += v
end
producer.join
raise unless sum == 4950

# multiple producers/consumers
ch2 = Channel.new(2)
prods = 4.times.map { |p_| Thread.new { 25.times { |i| ch2.send(1) } } }
total = 0
cons = Thread.new { 100.times { total += ch2.receive } }
prods.each(&:join); cons.join
raise unless total == 100

# arrays.md: persistent vector
BITS = 2
WIDTH = 1 << BITS

class PVec
  def initialize(depth, root) = (@depth = depth; @root = root)
  attr_reader :root

  def self.zeros(depth)
    node = 0
    depth.times { node = Array.new(WIDTH, node) }
    new(depth, node)
  end

  def [](i)
    node = @root
    ((@depth - 1) * BITS).step(0, -BITS) { |sh| node = node[(i >> sh) & (WIDTH - 1)] }
    node
  end

  def set(i, v)
    PVec.new(@depth, set_node(@root, @depth, i, v))
  end

  private def set_node(node, depth, i, v)
    return v if depth.zero?
    sh = (depth - 1) * BITS
    k = (i >> sh) & (WIDTH - 1)
    copy = node.dup
    copy[k] = set_node(node[k], depth - 1, i, v)
    copy
  end
end

v1 = PVec.zeros(3)
v2 = v1.set(37, :x)
raise unless v1[37] == 0 && v2[37] == :x
raise unless v1.root[0].equal?(v2.root[0])      # untouched branch shared
raise if v1.root.equal?(v2.root)
64.times { |i| raise unless v2[i] == (i == 37 ? :x : 0) }
v3 = (0...64).reduce(PVec.zeros(3)) { |v, i| v.set(i, i * 2) }
64.times { |i| raise unless v3[i] == i * 2 }

# frames.md: mini VM with call frames
def vm_run(funcs, entry)
  stack  = []
  frames = [[funcs[entry], 0, []]]
  until frames.empty?
    frame = frames.last
    func, pc = frame[0], frame[1]
    insn = func[:code][pc]
    frame[1] += 1
    case insn[0]
    when :push then stack << insn[1]
    when :load then stack << frame[2][insn[1]]
    when :add  then stack << stack.pop + stack.pop
    when :call
      callee = funcs[insn[1]]
      args = stack.pop(callee[:argc])
      frames << [callee, 0, args]
    when :ret
      frames.pop
    end
  end
  stack.pop
end

funcs = {
  "double" => { argc: 1, code: [[:load, 0], [:load, 0], [:add], [:ret]] },
  "main"   => { argc: 0, code: [[:push, 21], [:call, "double"], [:ret]] },
}
raise unless vm_run(funcs, "main") == 42

funcs2 = {
  "add3"  => { argc: 3, code: [[:load, 0], [:load, 1], [:add], [:load, 2], [:add], [:ret]] },
  "twice" => { argc: 1, code: [[:load, 0], [:push, 1], [:push, 2], [:push, 3],
                               [:call, "add3"], [:add], [:ret]] },
  "main"  => { argc: 0, code: [[:push, 10], [:call, "twice"], [:ret]] },
}
raise unless vm_run(funcs2, "main") == 16

puts "ALL OK (iteration 11)"
