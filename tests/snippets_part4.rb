# strings.md: Rope
class Rope
  Leaf   = Struct.new(:str)
  Concat = Struct.new(:left, :right, :weight)

  def initialize(node) = @node = node
  def self.of(s) = new(Leaf.new(s))
  attr_reader :node

  def length(n = @node)
    n.is_a?(Leaf) ? n.str.length : n.weight + length(n.right)
  end

  def +(other)
    Rope.new(Concat.new(@node, other.node, length))
  end

  def [](i, n = @node)
    return n.str[i] if n.is_a?(Leaf)
    i < n.weight ? self[i, n.left] : self[i - n.weight, n.right]
  end

  def to_s(n = @node)
    n.is_a?(Leaf) ? n.str : to_s(n.left) + to_s(n.right)
  end
end

r = Rope.of("Hello") + Rope.of(" ") + Rope.of("World")
raise unless r.length == 11
raise unless r[6] == "W" && r[0] == "H" && r[10] == "d"
raise unless r.to_s == "Hello World"

# regexp.md: Pike VM + Thompson compile
def pike_match?(prog, input)
  threads = add_thread([], prog, 0)
  input.each_char do |c|
    next_threads = []
    threads.each do |pc|
      op, a, = prog[pc]
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

def rcompile(re, prog = [])
  case re
  in [:char, c]   then prog << [:char, c]
  in [:cat, a, b] then rcompile(a, prog)
                       rcompile(b, prog)
  in [:alt, a, b]
    sp = prog.size
    prog << [:split, nil, nil]
    rcompile(a, prog)
    jp = prog.size
    prog << [:jmp, nil]
    prog[sp][1] = sp + 1
    prog[sp][2] = prog.size
    rcompile(b, prog)
    prog[jp][1] = prog.size
  in [:star, a]
    sp = prog.size
    prog << [:split, sp + 1, nil]
    rcompile(a, prog)
    prog << [:jmp, sp]
    prog[sp][2] = prog.size
  end
  prog
end

def compile_regex(re) = rcompile(re) << [:match]

re = [:cat, [:char, "a"],
      [:cat, [:star, [:alt, [:char, "b"], [:char, "c"]]], [:char, "d"]]]
prog = compile_regex(re)
raise unless pike_match?(prog, "abcbd")
raise unless pike_match?(prog, "ad")
raise unless pike_match?(prog, "abx") == false
raise unless pike_match?(prog, "abc") == false
re2 = [:alt, [:char, "x"], [:star, [:char, "y"]]]
prog2 = compile_regex(re2)
raise unless pike_match?(prog2, "x")
raise unless pike_match?(prog2, "")
raise unless pike_match?(prog2, "yyy")
raise unless pike_match?(prog2, "xy") == false

# trees.md: AVL insert
AVLNode = Struct.new(:key, :left, :right, :height)

def h(n) = n ? n.height : 0
def renew(n) = (n.height = 1 + [h(n.left), h(n.right)].max; n)
def bal(n) = h(n.left) - h(n.right)

def rot_right(y)
  x = y.left
  y.left = x.right
  x.right = renew(y)
  renew(x)
end

def rot_left(x)
  y = x.right
  x.right = y.left
  y.left = renew(x)
  renew(y)
end

def avl_insert(n, key)
  return AVLNode.new(key, nil, nil, 1) unless n
  if    key < n.key then n.left  = avl_insert(n.left, key)
  elsif key > n.key then n.right = avl_insert(n.right, key)
  else  return n
  end
  renew(n)
  if bal(n) > 1
    n.left = rot_left(n.left) if bal(n.left) < 0
    rot_right(n)
  elsif bal(n) < -1
    n.right = rot_right(n.right) if bal(n.right) > 0
    rot_left(n)
  else
    n
  end
end

def check_bst(n, lo = nil, hi = nil)
  return true unless n
  return false if lo && n.key <= lo
  return false if hi && n.key >= hi
  check_bst(n.left, lo, n.key) && check_bst(n.right, n.key, hi)
end

def check_avl(n)
  return true unless n
  bal(n).abs <= 1 && check_avl(n.left) && check_avl(n.right)
end

root = nil
(1..1023).each { |k| root = avl_insert(root, k) }
raise unless h(root) <= 11 && h(root) >= 10
raise unless check_bst(root) && check_avl(root)

root2 = nil
[5, 3, 8, 1, 4, 7, 9, 2, 6].each { |k| root2 = avl_insert(root2, k) }
raise unless check_bst(root2) && check_avl(root2)
require "set"
rng = Random.new(42)
root3 = nil
keys = 200.times.map { rng.rand(10_000) }.uniq
keys.each { |k| root3 = avl_insert(root3, k) }
raise unless check_bst(root3) && check_avl(root3)
collect = ->(n, acc) { n ? (collect.(n.left, acc); acc << n.key; collect.(n.right, acc); acc) : acc }
raise unless collect.(root3, []) == keys.sort

puts "ALL OK (iteration 9)"
