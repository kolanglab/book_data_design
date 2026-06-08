# prolog.md: unify + trail + backtracking
class LogicVar
  def initialize = @ref = self
  def bound? = !@ref.equal?(self)
  def bind(term) = @ref = term
  def unbind = @ref = self
  def deref
    v = self
    v = v.instance_variable_get(:@ref) while v.is_a?(LogicVar) && v.bound?
    v
  end
end

Compound = Struct.new(:functor, :args)

def bind!(var, term, trail)
  var.bind(term)
  trail << var
  true
end

def walk(t) = t.is_a?(LogicVar) ? t.deref : t

def unify(a, b, trail)
  a, b = walk(a), walk(b)
  return true if a.equal?(b)
  return bind!(a, b, trail) if a.is_a?(LogicVar)
  return bind!(b, a, trail) if b.is_a?(LogicVar)
  return a == b unless a.is_a?(Compound) && b.is_a?(Compound)
  a.functor == b.functor && a.args.size == b.args.size &&
    a.args.zip(b.args).all? { |x, y| unify(x, y, trail) }
end

# book example from the unify section
x, y = LogicVar.new, LogicVar.new
trail = []
raise unless unify(Compound.new(:point, [x, 2]), Compound.new(:point, [1, y]), trail)
raise unless x.deref == 1 && y.deref == 2

# backtracking demo
x2 = LogicVar.new
goal = Compound.new(:color, [x2])
candidates = [Compound.new(:color, [:red]),
              Compound.new(:color, [:green])]
trail2 = []
found = nil
tried = []
candidates.each do |head|
  mark = trail2.size
  ok = unify(goal, head, trail2)
  tried << x2.deref if ok
  if ok && x2.deref == :green
    found = x2.deref
    break
  end
  trail2.pop.unbind while trail2.size > mark
end
raise unless found == :green
raise unless tried == [:red, :green]   # red was tried first, then undone

# partial unification failure must also be undoable
a1, b1 = LogicVar.new, LogicVar.new
trail3 = []
ok = unify(Compound.new(:f, [a1, :one]), Compound.new(:f, [:x, :two]), trail3)
raise if ok
trail3.pop.unbind while trail3.size > 0
raise if a1.bound?

# forth.md: MiniForth
class MiniForth
  def initialize
    @stack = []
    @dict = {
      "+"   => -> { @stack << @stack.pop + @stack.pop },
      "*"   => -> { @stack << @stack.pop * @stack.pop },
      "dup" => -> { @stack << @stack.last },
      "."   => -> { print @stack.pop, " " },
    }
  end
  attr_reader :stack

  def make_word(src) = -> { run(src) }   # 値で捕まえる（捕獲バグ除け）

  def run(src)
    words = src.split
    until words.empty?
      w = words.shift
      if w == ":"
        name = words.shift
        body = words.take_while { |t| t != ";" }
        words.shift(body.size + 1)
        @dict[name] = make_word(body.join(" "))
      elsif (impl = @dict[w])
        impl.call
      else
        @stack << Integer(w)
      end
    end
  end
end

f = MiniForth.new
f.run(": square dup * ;   5 square 3 +")
raise unless f.stack == [28]
f2 = MiniForth.new
f2.run(": quad dup + dup + ;  : add1 1 + ;  2 quad add1")
raise unless f2.stack == [9]

# smalltalk.md: ObjectTable become!
class ObjectTable
  def initialize = @slots = []
  def register(obj) = (@slots << obj; @slots.size - 1)
  def deref(handle) = @slots[handle]
  def become!(h1, h2)
    @slots[h1], @slots[h2] = @slots[h2], @slots[h1]
  end
end

table = ObjectTable.new
a = table.register("old object")
b = table.register("new object")
ref1, ref2 = a, a
table.become!(a, b)
raise unless table.deref(ref1) == "new object"
raise unless table.deref(ref2) == "new object"
raise unless table.deref(b) == "old object"   # two-way swap

puts "ALL OK (iteration 12)"
