module ProductionBreakpoints
  class NotMyClass
  end

  class MyClass
    def some_method
      a = 1
      sleep 0.5
      b = a + 1
    end
  end
end
