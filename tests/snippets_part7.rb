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

# closures.md: async/await の手動脱糖（状態機械）
class FetchSum
  Await = Struct.new(:url)
  Done  = Struct.new(:value)

  def initialize = @state = :start

  def resume(result = nil)
    case @state
    when :start
      @state = :wait_a
      Await.new("a.example")
    when :wait_a
      @a = result
      @state = :wait_b
      Await.new("b.example")
    when :wait_b
      @state = :done
      Done.new(@a + result)
    end
  end
end

task = FetchSum.new
step = task.resume
while step.is_a?(FetchSum::Await)
  result = step.url.length
  step = task.resume(result)
end
raise unless step.value == 18
raise unless task.instance_variable_get(:@state) == :done

# concurrency.md: 楽観的 STM の最小実装
class TVar
  attr_accessor :value, :version
  def initialize(v) = (@value = v; @version = 0)
end

COMMIT_LOCK = Mutex.new

def atomically
  loop do
    tx = { reads: {}, writes: {} }
    result = yield tx
    ok = COMMIT_LOCK.synchronize do
      if tx[:reads].all? { |tvar, ver| tvar.version == ver }
        tx[:writes].each { |tvar, v| tvar.value = v; tvar.version += 1 }
        true
      end
    end
    return result if ok
  end
end

def tx_read(tx, tvar)
  return tx[:writes][tvar] if tx[:writes].key?(tvar)
  tx[:reads][tvar] = tvar.version unless tx[:reads].key?(tvar)
  tvar.value
end

def tx_write(tx, tvar, v) = tx[:writes][tvar] = v

acc_a = TVar.new(100)
acc_b = TVar.new(0)
10.times.map {
  Thread.new do
    10.times do
      atomically do |tx|
        tx_write(tx, acc_a, tx_read(tx, acc_a) - 1)
        tx_write(tx, acc_b, tx_read(tx, acc_b) + 1)
      end
    end
  end
}.each(&:join)
raise unless [acc_a.value, acc_b.value] == [0, 100]

# time.md: Time.at の in: は固定オフセットのみ受け付ける
t = Time.at(1780890896, in: "+09:00")
raise unless t.to_s == "2026-06-08 12:54:56 +0900"
raise unless Time.at(1780890896, in: "+01:00").to_s == "2026-06-08 04:54:56 +0100"
begin
  Time.at(1780890896, in: "Asia/Tokyo")   # ゾーン名は不可（本文の記述どおり）
  raise "Time.at should reject IANA zone names"
rescue ArgumentError
end

# time.md: ISO 8601 の辞書順=時刻順は、オフセット混在では壊れる
require "time"
iso_a = "2026-06-08T09:00:00+09:00"
iso_b = "2026-06-08T00:30:00Z"
raise unless Time.parse(iso_a) < Time.parse(iso_b)  # 時刻としては a が前
raise unless (iso_a <=> iso_b) > 0                  # 文字列としては a が後

puts "ALL OK (iteration 12)"
