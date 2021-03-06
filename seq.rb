class Number < Struct.new(:value)
  def inspect
    "<<#{self}>>"
  end
  def to_s
    "#{value}"
  end
  def reducible?
    false
  end
end

class Add < Struct.new(:left, :right)
  def inspect
    "<<#{self}>>"
  end
  def to_s
    "#{left} + #{right}"
  end
  def reducible?
    true
  end
  def reduce(environment)
    if left.reducible?
      Add.new(left.reduce(environment), right) # 用规约结果创建新 Add 用于继续规约
    elsif right.reducible?
      Add.new(left, right.reduce(environment)) # 用规约结果创建新 Add 用于继续规约
    else
      Number.new(left.value + right.value) # 求出结果
    end
  end
end

class Multiply < Struct.new(:left, :right)
  def inspect
    "<<#{self}>>"
  end
  def to_s
    "#{left} * #{right}"
  end
  def reducible?
    true
  end
  def reduce(environment)
    if left.reducible?
      Multiply.new(left.reduce(environment), right)
    elsif right.reducible?
      Multiply.new(left, right.reduce(environment))
    else
      Number.new(left.value * right.value)
    end
  end
end

class Boolean < Struct.new(:value)
  def to_s
    value.to_s
  end
  def inspect
    "<<#{self}>>"
  end
  def reducible?
    false
  end
end

class LessThan < Struct.new(:left, :right)
  def to_s
    "#{left} < #{right}"
  end
  def inspect
    "<<#{self}>>"
  end
  def reducible?
    true
  end
  def reduce(environment)
    if left.reducible?
      LessThan.new(left.reduce(environment), right)
    elsif right.reducible?
      LessThan.new(left, right.reduce(environment))
    else
      Boolean.new(left.value < right.value)
    end
  end
end

class Variable < Struct.new(:name)
  # 为什么变量只有一个 :name 属性呢？
  def to_s
    name.to_s
  end
  def inspect
    "<<#{self}>>"
  end
  def reducible?
    true
  end
  def reduce(environment)
    environment[name]
    # 答案：因为变量的值放在环境里了
  end
end
class DoNothing
  def to_s
    'do-nothing'
  end
  def inspect
    "<<#{self}>>"
  end
  def ==(other_statement) # 你没有看错，Ruby 里的方法名可以是 ==
    other_statement.instance_of?(DoNothing)
  end
  def reducible?
    false
  end
end

class Assign < Struct.new(:name, :expression)
  def to_s
    "#{name} = #{expression}"
  end
  def inspect
    "<<#{self}>>"
  end
  def reducible?
    true
  end
  def reduce(environment)
    if expression.reducible?
      new_expression = expression.reduce(environment)
      new_assign = Assign.new(name, new_expression)
      [new_assign, environment] # 此处的 [a, b] 表示返回 a 和 b 两个值
    else
      new_environment = environment.merge({ name => expression })
      [DoNothing.new, new_environment] # 此处的 [a, b] 表示返回 a 和 b 两个值
    end
  end
end

class If < Struct.new(:true_or_false, :if_true, :if_false)
  def to_s; "if (#{true_or_false}) { #{if_true} } else { #{if_false} }"; end
  def inspect; "<<#{self}>>"; end
  def reducible?; true; end 
  def reduce(environment)
    if true_or_false.reducible? 
      [If.new(true_or_false.reduce(environment), if_true, if_false), environment] 
    else
      case true_or_false
        when Boolean.new(true) 
          [if_true, environment] 
        when Boolean.new(false)
          [if_false, environment]
      end
    end
  end
end

class Sequence < Struct.new(:first, :second)
  def to_s; "#{first}; #{second}" end
  def inspect; "<<#{self}>>" end
  def reducible?; true end
  def reduce(environment)
    case first 
      when DoNothing.new 
        [second, environment]
      else
        reduced_first, reduced_environment = first.reduce(environment)
        [Sequence.new(reduced_first, second), reduced_environment]
    end
  end
end


class Machine < Struct.new(:statement, :environment)
  def step
    self.statement, self.environment = statement.reduce(environment)
  end
  def run
    while statement.reducible?
      puts "#{statement}, #{environment}"
      step
    end
    puts "#{statement}, #{environment}"
  end
end

# x = 1 + 1; y = x + 3
Machine.new(Sequence.new(
  Assign.new(:x, Add.new(Number.new(1), Number.new(1))),
  Assign.new(:y, Add.new(Variable.new(:x), Number.new(3)))
), {}).run
