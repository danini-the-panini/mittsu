require 'benchmark/ips'

class Foo
  attr_accessor :foo
  def set_instance_variable(key, value)
    sym = "@#{key}".to_sym
    self.instance_variable_set(sym, value)
  end
  def set_with_method_send(key, value)
    sym = "#{key}="
    self.send(sym, value)
  end
end

f = Foo.new

Benchmark.ips do |x|
  x.report('instance-variable-set') do |times|
    i = 0
    while i < times
      f.set_instance_variable(:foo, i)
      i += 1
    end
  end

  x.report('method-send') do |times|
    i = 0
    while i < times
      f.set_with_method_send(:foo, i)
      i += 1
    end
  end

  x.compare!
end
