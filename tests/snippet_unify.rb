class LogicVar
  def initialize = @ref = self
  def bound? = @ref.equal?(self) ? false : true
  def bind(term) = @ref = term
  def deref
    v = self
    v = v.instance_variable_get(:@ref) while v.is_a?(LogicVar) && v.bound?
    v
  end
end
Compound = Struct.new(:functor, :args)
def bind_(var, term, trail)
  var.bind(term)
  trail << var
  true
end
def walk(t) = t.is_a?(LogicVar) ? t.deref : t
def unify(a, b, trail)
  a, b = walk(a), walk(b)
  return true if a.equal?(b)
  return bind_(a, b, trail) if a.is_a?(LogicVar)
  return bind_(b, a, trail) if b.is_a?(LogicVar)
  return a == b unless a.is_a?(Compound) && b.is_a?(Compound)
  a.functor == b.functor && a.args.size == b.args.size &&
    a.args.zip(b.args).all? { |x, y| unify(x, y, trail) }
end
x, y = LogicVar.new, LogicVar.new
trail = []
raise unless unify(Compound.new(:point, [x, 2]), Compound.new(:point, [1, y]), trail)
raise unless x.deref == 1 && y.deref == 2 && trail.size == 2
raise if unify(Compound.new(:point, [1]), Compound.new(:line, [1]), [])
puts "UNIFY OK"
