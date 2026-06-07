# --- symbol-table.md ---
class SymbolTable
  def initialize(size = 16)
    @buckets = Array.new(size) { [] }
  end
  def hash_index(name) = name.bytes.sum % @buckets.size
  def []=(name, value)
    bucket = @buckets[hash_index(name)]
    pair = bucket.find { |k, _| k == name }
    if pair then pair[1] = value else bucket << [name, value] end
  end
  def [](name)
    bucket = @buckets[hash_index(name)]
    pair = bucket.find { |k, _| k == name }
    pair && pair[1]
  end
end
st = SymbolTable.new; st["x"] = 1; st["abc"] = 2; st["cba"] = 3
raise unless st["x"] == 1 && st["abc"] == 2 && st["cba"] == 3 && st["nope"].nil?

class Scope
  def initialize(parent = nil)
    @table = {}; @parent = parent
  end
  def define(name, value) = @table[name] = value
  def lookup(name)
    if @table.key?(name) then @table[name]
    elsif @parent then @parent.lookup(name)
    else nil end
  end
end
g = Scope.new; g.define("x", :gx); l = Scope.new(g); l.define("x", :lx)
raise unless l.lookup("x") == :lx && l.lookup("y").nil? && g.lookup("x") == :gx

class ScopeStack
  def initialize = @stack = [{}]
  def enter = @stack.push({})
  def leave = @stack.pop
  def define(name, value) = @stack.last[name] = value
  def lookup(name)
    @stack.reverse_each { |t| return t[name] if t.key?(name) }
    nil
  end
end
ss = ScopeStack.new; ss.define("a", 1); ss.enter; ss.define("a", 2)
raise unless ss.lookup("a") == 2
ss.leave
raise unless ss.lookup("a") == 1

# --- identifier.md ---
class Interner
  def initialize = @pool = {}
  def intern(str) = @pool[str] ||= str.dup.freeze
end
i = Interner.new
raise unless i.intern("counter").equal?(i.intern("counter"))

class IdTable
  def initialize
    @id_of = {}; @name_of = []
  end
  def to_id(name)
    @id_of[name] ||= begin
      @name_of << name
      @name_of.size - 1
    end
  end
  def to_name(id) = @name_of[id]
end
ids = IdTable.new
raise unless ids.to_id("if") == 0 && ids.to_id("while") == 1 && ids.to_id("if") == 0 && ids.to_name(1) == "while"

LOCAL = 0b000; INSTANCE = 0b001; GLOBAL = 0b010
def make_id(serial, kind) = (serial << 3) | kind
def kind_of(id) = id & 0b111
def serial_of(id) = id >> 3
id = make_id(42, INSTANCE)
raise unless kind_of(id) == INSTANCE && serial_of(id) == 42

# --- syntax-tree.md ---
NumberNode = Struct.new(:value)
VarNode    = Struct.new(:name)
BinOpNode  = Struct.new(:op, :left, :right)
tree = BinOpNode.new(:+, NumberNode.new(2), BinOpNode.new(:*, NumberNode.new(3), NumberNode.new(4)))
def evaluate(node, env)
  case node
  when NumberNode then node.value
  when VarNode then env.fetch(node.name)
  when BinOpNode
    l = evaluate(node.left, env); r = evaluate(node.right, env)
    l.send(node.op, r)
  end
end
raise unless evaluate(tree, {}) == 14

# --- numbers.md BigInt ---
class BigInt
  BASE = 10000
  def initialize(digits) = @digits = digits
  def +(other)
    result = []; carry = 0
    [@digits.size, other.digits.size].max.times do |i|
      sum = (@digits[i] || 0) + (other.digits[i] || 0) + carry
      result << sum % BASE
      carry = sum / BASE
    end
    result << carry if carry > 0
    BigInt.new(result)
  end
  attr_reader :digits
end
a = BigInt.new([9999, 9999])
b = BigInt.new([1])
raise unless (a + b).digits == [0, 0, 1]

# --- strings.md MyString ---
class MyString
  def initialize(bytes)
    @bytes = bytes; @length = bytes.size
  end
  def byte_at(i) = @bytes[i]
  attr_reader :length
end
s = MyString.new("ABC".bytes)
raise unless s.length == 3 && s.byte_at(0) == 65

# --- hashes.md OpenHash & Point ---
class OpenHash
  def initialize(cap = 8)
    @keys = Array.new(cap); @vals = Array.new(cap)
  end
  def []=(key, val)
    i = key.hash % @keys.size
    until @keys[i].nil? || @keys[i] == key
      i = (i + 1) % @keys.size
    end
    @keys[i] = key; @vals[i] = val
  end
  def [](key)
    i = key.hash % @keys.size
    until @keys[i].nil?
      return @vals[i] if @keys[i] == key
      i = (i + 1) % @keys.size
    end
    nil
  end
end
oh = OpenHash.new(4)
oh[:a] = 1; oh[:b] = 2; oh[:c] = 3
raise unless oh[:a] == 1 && oh[:b] == 2 && oh[:c] == 3 && oh[:zz].nil?

Point = Struct.new(:x, :y) do
  def hash = [x, y].hash
  def eql?(o) = o.is_a?(Point) && x == o.x && y == o.y
end
h = {}; h[Point.new(1, 2)] = "o"
raise unless h[Point.new(1, 2)] == "o"

# --- memory.md FreeList ---
Slot = Struct.new(:next_free)
class FreeList
  def initialize(slots)
    @head = nil
    slots.each { |s| free(s) }
  end
  def allocate
    slot = @head
    @head = slot.next_free
    slot
  end
  def free(slot)
    slot.next_free = @head
    @head = slot
  end
end
fl = FreeList.new([Slot.new, Slot.new])
x = fl.allocate; y = fl.allocate
raise unless x && y && !x.equal?(y)
fl.free(x)
raise unless fl.allocate.equal?(x)

# --- memory.md serialize ---
Obj = Struct.new(:fields)
def serialize(obj, seen = {})
  if (id = seen[obj.object_id])
    return [:backref, id]
  end
  seen[obj.object_id] = seen.size
  [:object, obj.class.name, obj.fields.map { |f| f.is_a?(Obj) ? serialize(f, seen) : f }]
end
a2 = Obj.new([]); b2 = Obj.new([a2]); a2.fields << b2
r = serialize(a2)
raise unless r[0] == :object && r[2][0][2][0] == [:backref, 0]

# --- closures.md make_counter ---
def make_counter
  count = 0
  -> { count += 1 }
end
c1 = make_counter; c2 = make_counter
raise unless c1.call == 1 && c1.call == 2 && c2.call == 1

# --- lazy.md Thunk ---
class Thunk
  def initialize(&recipe)
    @recipe = recipe; @done = false; @value = nil
  end
  def force
    unless @done
      @value = @recipe.call
      @done = true
      @recipe = nil
    end
    @value
  end
end
n = 0
t = Thunk.new { n += 1; 6 * 7 }
raise unless t.force == 42 && t.force == 42 && n == 1

# --- lazy.md Enumerator::Lazy example ---
raise unless (1..Float::INFINITY).lazy.map { |x| x * x }.select(&:even?).first(3) == [4, 16, 36]

# --- tcl.md TclObj ---
class TclObj
  def initialize(str) = (@str = str; @int = nil)
  def as_int = (@int ||= Integer(@str))
  def incr!
    v = as_int + 1
    @int = v
    @str = nil
  end
  def to_s = (@str ||= @int.to_s)
end
o = TclObj.new("42"); o.incr!
raise unless o.to_s == "43"

# --- time.md fixed utc_offset_at ---
Zone = Struct.new(:transitions, :offsets)
z = Zone.new([100, 200], [[1, "A"], [2, "B"]])
def utc_offset_at(zone, t)
  i = zone.transitions.bsearch_index { |tr| tr > t }
  case i
  when 0   then zone.offsets[0]
  when nil then zone.offsets[-1]
  else          zone.offsets[i - 1]
  end
end
raise unless utc_offset_at(z, 50)[1] == "A"
raise unless utc_offset_at(z, 150)[1] == "A"
raise unless utc_offset_at(z, 250)[1] == "B"

# --- prolog.md LogicVar ---
class LogicVar
  def initialize = @ref = self
  def bound? = !@ref.equal?(self)
  def bind(term) = @ref = term
  def deref
    v = self
    v = v.instance_variable_get(:@ref) while v.is_a?(LogicVar) && v.bound?
    v
  end
end
v1 = LogicVar.new; v2 = LogicVar.new
v1.bind(v2); v2.bind(42)
raise unless v1.deref == 42

# --- time.md Date examples ---
require "date"
raise unless (Date.new(2026, 1, 31) >> 1) == Date.new(2026, 2, 28)
raise unless (Date.new(2026, 1, 31) + 30) == Date.new(2026, 3, 2)

puts "ALL OK (iteration 7)"
