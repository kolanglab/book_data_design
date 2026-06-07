# syntax-tree.md: AST -> bytecode compiler + stack VM
NumberNode = Struct.new(:value)
VarNode    = Struct.new(:name)
BinOpNode  = Struct.new(:op, :left, :right)
tree = BinOpNode.new(:+, NumberNode.new(2), BinOpNode.new(:*, NumberNode.new(3), NumberNode.new(4)))

def compile(node, out = [])
  case node
  when NumberNode then out << [:push, node.value]
  when VarNode    then out << [:load, node.name]
  when BinOpNode
    compile(node.left, out)
    compile(node.right, out)
    out << [:binop, node.op]
  end
  out
end

def run(code, env = {})
  stack = []
  code.each do |op, arg|
    case op
    when :push  then stack.push(arg)
    when :load  then stack.push(env.fetch(arg))
    when :binop then b = stack.pop
                     a = stack.pop
                     stack.push(a.send(arg, b))
    end
  end
  stack.pop
end

raise unless compile(tree) == [[:push, 2], [:push, 3], [:push, 4], [:binop, :*], [:binop, :+]]
raise unless run(compile(tree)) == 14
t2 = BinOpNode.new(:-, VarNode.new("x"), NumberNode.new(1))
raise unless run(compile(t2), { "x" => 10 }) == 9

# memory.md: mark & sweep GC
class GCHeap
  Obj = Struct.new(:refs, :marked)

  def initialize = (@objects = []; @roots = [])
  attr_reader :roots

  def allocate(refs = [])
    obj = Obj.new(refs, false)
    @objects << obj
    obj
  end

  def collect
    work = @roots.dup
    until work.empty?
      obj = work.pop
      next if obj.marked
      obj.marked = true
      work.concat(obj.refs)
    end
    @objects.select!(&:marked)
    @objects.each { |o| o.marked = false }
  end

  def live_count = @objects.size
end

heap = GCHeap.new
a = heap.allocate
b = heap.allocate([a])
heap.allocate([])
c = heap.allocate; c.refs << c
heap.roots << b
heap.collect
raise unless heap.live_count == 2
heap.collect                       # idempotent: marks were reset
raise unless heap.live_count == 2
heap.roots.clear
heap.collect
raise unless heap.live_count == 0

# objects.md: shape transitions
class Shape
  def initialize(parent = nil, name = nil)
    @fields = parent ? parent.fields.merge(name => parent.fields.size) : {}
    @transitions = {}
  end
  attr_reader :fields

  def index_of(name) = @fields[name]

  def transition(name)
    @transitions[name] ||= Shape.new(self, name)
  end
end

ROOT_SHAPE = Shape.new

class ShapedObject
  def initialize = (@shape = ROOT_SHAPE; @values = [])

  def set_ivar(name, value)
    unless (i = @shape.index_of(name))
      @shape = @shape.transition(name)
      i = @shape.index_of(name)
    end
    @values[i] = value
  end

  def get_ivar(name)
    (i = @shape.index_of(name)) && @values[i]
  end
  attr_reader :shape
end

u1 = ShapedObject.new
u1.set_ivar(:@name, "Alice"); u1.set_ivar(:@age, 30)
u2 = ShapedObject.new
u2.set_ivar(:@name, "Bob"); u2.set_ivar(:@age, 25)
raise unless u1.shape.equal?(u2.shape)
raise unless u1.get_ivar(:@age) == 30 && u2.get_ivar(:@name) == "Bob"
u3 = ShapedObject.new
u3.set_ivar(:@age, 1); u3.set_ivar(:@name, "x")   # different order
raise if u3.shape.equal?(u1.shape)
u1.set_ivar(:@age, 31)                            # update, no transition
raise unless u1.get_ivar(:@age) == 31 && u1.shape.equal?(u2.shape)

# serialize.md: varint
def varint_encode(n)
  bytes = []
  loop do
    b = n & 0x7f
    n >>= 7
    bytes << (n.zero? ? b : b | 0x80)
    break if n.zero?
  end
  bytes
end
raise unless varint_encode(300) == [0xAC, 0x02]
raise unless varint_encode(0) == [0]
raise unless varint_encode(127) == [127]
raise unless varint_encode(128) == [0x80, 0x01]

# serialize.md: Marshal cycle round-trip & header
arr = []; arr << arr
back = Marshal.load(Marshal.dump(arr))
raise unless back.equal?(back[0])
raise unless Marshal.dump(42).bytes[2] == 105   # 'i'

puts "ALL OK (iteration 8)"
