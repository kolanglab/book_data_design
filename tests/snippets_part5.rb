# lazy.md: Thunk + Stream
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

class Stream
  def initialize(head, &tail) = (@head = head; @tail = Thunk.new(&tail))
  attr_reader :head
  def tail = @tail.force

  def self.from(n) = new(n) { from(n + 1) }

  def map(&f) = Stream.new(f.(head)) { tail.map(&f) }
  def take(k) = k.zero? ? [] : [head] + tail.take(k - 1)
end

raise unless Stream.from(0).map { |x| x * x }.take(5) == [0, 1, 4, 9, 16]

def fibs(a = 0, b = 1) = Stream.new(a) { fibs(b, a + b) }
raise unless fibs.take(8) == [0, 1, 1, 2, 3, 5, 8, 13]

calls = 0
s = Stream.from(0).map { |x| calls += 1; x }
s.take(3)
first = calls            # take(3) は先頭3要素+先読み1のサンクを評価する
s.take(3)
raise unless calls == first   # memoized: 二度目の走査では一切再計算されない
raise unless first == 4

# closures.md: Upvalue
class Upvalue
  def initialize(stack, index) = (@stack = stack; @index = index)

  def value
    @stack ? @stack[@index] : @closed
  end

  def value=(v)
    if @stack then @stack[@index] = v else @closed = v end
  end

  def close!
    @closed = @stack[@index]
    @stack = nil
  end
end

stack = [10]
uv  = Upvalue.new(stack, 0)
inc = -> { uv.value += 1 }
get = -> { uv.value }
inc.call
raise unless stack[0] == 11
uv.close!
stack[0] = 99
inc.call
raise unless get.call == 12 && stack[0] == 99

# time.md: JDN conversions vs Date
def civil_to_jdn(y, m, d)
  a  = (14 - m) / 12
  yy = y + 4800 - a
  mm = m + 12 * a - 3
  d + (153 * mm + 2) / 5 + 365 * yy +
    yy / 4 - yy / 100 + yy / 400 - 32045
end

def jdn_to_civil(j)
  a = j + 32044
  b = (4 * a + 3) / 146097
  c = a - 146097 * b / 4
  d_ = (4 * c + 3) / 1461
  e = c - 1461 * d_ / 4
  m_ = (5 * e + 2) / 153
  [100 * b + d_ - 4800 + m_ / 10,
   m_ + 3 - 12 * (m_ / 10),
   e - (153 * m_ + 2) / 5 + 1]
end

require "date"
# 先発グレゴリオ暦(Date::GREGORIAN)で突き合わせる。既定(ITALY)は
# 1582年改暦を再現するので、それ以前の日付はユリウス暦になりずれる。
[[2026, 6, 8], [2000, 2, 29], [1582, 10, 15], [1, 1, 1], [2100, 2, 28]].each do |y, m, d|
  jd = Date.new(y, m, d, Date::GREGORIAN).jd
  raise "jdn mismatch #{[y, m, d]}" unless civil_to_jdn(y, m, d) == jd
  raise "civil mismatch #{jd}" unless jdn_to_civil(jd) == [y, m, d]
end
rng = Random.new(1)
50.times do
  jd = 1_800_000 + rng.rand(1_000_000)
  y, m, d = jdn_to_civil(jd)
  raise unless Date.new(y, m, d, Date::GREGORIAN).jd == jd
  raise unless civil_to_jdn(y, m, d) == jd
end

# hashes.md: OrderedDict
class OrderedDict
  def initialize
    @index   = Array.new(8)
    @entries = []
  end

  def find_slot(key, h)
    i = h % @index.size
    until @index[i].nil?
      e = @entries[@index[i]]
      return i if e[0] == h && e[1].eql?(key)
      i = (i + 1) % @index.size
    end
    i
  end

  def []=(key, value)
    h = key.hash
    i = find_slot(key, h)
    return @entries[@index[i]][2] = value if @index[i]
    if (@entries.size + 1) * 4 > @index.size * 3
      @index = Array.new(@index.size * 2)
      @entries.each_with_index { |e, n| @index[find_slot(e[1], e[0])] = n }
      i = find_slot(key, h)
    end
    @index[i] = @entries.size
    @entries << [h, key, value]
  end

  def [](key)
    n = @index[find_slot(key, key.hash)]
    n && @entries[n][2]
  end

  def each_pair = @entries.each { |_, k, v| yield k, v }
end

d = OrderedDict.new
d[:c] = 1; d[:a] = 2; d[:b] = 3; d[:a] = 20
order = []
d.each_pair { |k, v| order << [k, v] }
raise unless order == [[:c, 1], [:a, 20], [:b, 3]]
raise unless d[:a] == 20 && d[:zz].nil?
ref = {}
rng2 = Random.new(7)
200.times do
  k = "k#{rng2.rand(80)}"
  v = rng2.rand(1000)
  d[k] = v
  ref[k] = v
end
ref.each { |k, v| raise "mismatch #{k}" unless d[k] == v }
got = []
d.each_pair { |k, v| got << k if k.is_a?(String) }
raise unless got == ref.keys   # insertion order matches Ruby Hash's

# lists.md: PureQueue
class PureQueue
  def initialize(front = [], back = [])
    @front, @back = front, back
  end

  def push(x) = PureQueue.new(@front, [x] + @back)

  def pop
    if @front.empty?
      f = @back.reverse
      [f.first, PureQueue.new(f.drop(1), [])]
    else
      [@front.first, PureQueue.new(@front.drop(1), @back)]
    end
  end
end

q = PureQueue.new.push(1).push(2).push(3)
v1, q2 = q.pop
v2, q3 = q2.pop
v3, _ = q3.pop
raise unless [v1, v2, v3] == [1, 2, 3]
w, _ = q.pop
raise unless w == 1   # persistence: original q is intact

puts "ALL OK (iteration 10)"
