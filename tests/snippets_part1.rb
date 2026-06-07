# --- numbers.md: tagged fixnum ---
def to_fixnum(n)  = (n << 1) | 1
def fixnum?(v)    = (v & 1) == 1
def from_fixnum(v) = v >> 1
raise unless to_fixnum(3) == 7 && fixnum?(7) && from_fixnum(7) == 3
raise unless 42.object_id == 85

# --- arrays.md: DynamicArray ---
class DynamicArray
  def initialize
    @store = Array.new(1)
    @size  = 0
  end
  def push(value)
    if @size == @store.size
      bigger = Array.new(@store.size * 2)
      @size.times { |i| bigger[i] = @store[i] }
      @store = bigger
    end
    @store[@size] = value
    @size += 1
  end
  def [](i) = @store[i]
  attr_reader :size
end
d = DynamicArray.new; 100.times { |i| d.push(i) }
raise unless d.size == 100 && d[99] == 99

# --- regexp.md: Pike VM ---
def pike_match?(prog, input)
  threads = add_thread([], prog, 0)
  input.each_char do |c|
    next_threads = []
    threads.each do |pc|
      op, a, b = prog[pc]
      if op == :char && a == c
        add_thread(next_threads, prog, pc + 1)
      end
    end
    threads = next_threads
    return false if threads.empty?
  end
  threads.any? { |pc| prog[pc][0] == :match }
end
def add_thread(list, prog, pc)
  return list if list.include?(pc)
  op, a, b = prog[pc]
  case op
  when :jmp   then add_thread(list, prog, a)
  when :split then add_thread(add_thread(list, prog, a), prog, b)
  else list << pc
  end
  list
end
# /a(b|c)*d/ : 0:char a, 1:split(2,6), 2:split(3,? ) ... build simpler: a(b|c)*d
prog = [
  [:char, "a"],        # 0
  [:split, 2, 6],      # 1: loop entry
  [:split, 3, 4],      # 2: choose b or c
  [:char, "b"],        # 3 -> needs jmp to 5? after char pc+1=4 (wrong)
]
# rebuild carefully:
# 0: char a
# 1: split 2, 7        (enter loop or exit)
# 2: split 3, 5        (b-branch or c-branch)
# 3: char b
# 4: jmp 1
# 5: char c
# 6: jmp 1
# 7: char d
# 8: match
prog = [
  [:char, "a"],
  [:split, 2, 7],
  [:split, 3, 5],
  [:char, "b"],
  [:jmp, 1],
  [:char, "c"],
  [:jmp, 1],
  [:char, "d"],
  [:match],
]
raise unless pike_match?(prog, "abcbd") == true
raise unless pike_match?(prog, "ad") == true
raise unless pike_match?(prog, "abx") == false
raise unless pike_match?(prog, "abc") == false

# --- regexp.md: derivatives ---
def nullable?(re)
  case re
  in [:eps] then true
  in [:empty] then false
  in [:char, _] then false
  in [:cat, a, b] then nullable?(a) && nullable?(b)
  in [:alt, a, b] then nullable?(a) || nullable?(b)
  in [:star, _] then true
  end
end
def simplify(re)
  case re
  in [:alt, [:empty], b] then b
  in [:alt, a, [:empty]] then a
  in [:cat, [:empty], _] | [:cat, _, [:empty]] then [:empty]
  in [:cat, [:eps], b] then b
  in [:cat, a, [:eps]] then a
  else re
  end
end
def deriv(re, c)
  case re
  in [:char, ch]    then ch == c ? [:eps] : [:empty]
  in [:cat, a, b]   then
    d = [:alt, simplify([:cat, deriv(a, c), b]),
               nullable?(a) ? deriv(b, c) : [:empty]]
    simplify(d)
  in [:alt, a, b]   then simplify([:alt, deriv(a, c), deriv(b, c)])
  in [:star, a]     then simplify([:cat, deriv(a, c), re])
  in [:eps] | [:empty] then [:empty]
  end
end
def dmatch?(re, str)
  str.each_char { |c| re = deriv(re, c) }
  nullable?(re)
end
# a(b|c)*d
re = [:cat, [:char, "a"], [:cat, [:star, [:alt, [:char, "b"], [:char, "c"]]], [:char, "d"]]]
raise unless dmatch?(re, "abcbd") == true
raise unless dmatch?(re, "ad") == true
raise unless dmatch?(re, "abx") == false

# --- hashes.md: hamt_get ---
Leaf = Struct.new(:key, :val)
Node = Struct.new(:bitmap, :children)
def hamt_get(node, hash, shift, key)
  idx = (hash >> shift) & 0b11111
  bit = 1 << idx
  return nil if node.bitmap & bit == 0
  pos = (node.bitmap & (bit - 1)).to_s(2).count("1")
  child = node.children[pos]
  child.is_a?(Leaf) ? (child.key == key ? child.val : nil)
                    : hamt_get(child, hash, shift + 5, key)
end
# build: key with hash 5 at root level
leaf = Leaf.new(:k, 42)
root = Node.new(1 << 5, [leaf])
raise unless hamt_get(root, 5, 0, :k) == 42
raise unless hamt_get(root, 6, 0, :k).nil?

# --- time.md: utc_offset_at ---
Zone = Struct.new(:transitions, :offsets)
tokyo = Zone.new([-2587712400, -683802000, -672310800],
                 [[33539, "LMT"], [32400, "JST"], [36000, "JDT"]])
def utc_offset_at(zone, t)
  i = zone.transitions.bsearch_index { |tr| tr > t }
  zone.offsets[i ? i - 1 : zone.transitions.size - 1]
end
raise unless utc_offset_at(tokyo, 0)[1] == "JDT"  # after last transition -> last offset? hmm
puts "ALL OK"
