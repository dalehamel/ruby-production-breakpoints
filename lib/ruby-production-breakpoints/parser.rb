module ProductionBreakpoints

  # FIXME this class is a mess, figure out interface and properly separate private / public
  class Parser

    attr_reader :root_node

    def initialize(source_file)
      @root_node = RubyVM::AbstractSyntaxTree.parse_file(source_file)
      @source_lines = File.read(source_file).lines
      @logger = ProductionBreakpoints.logger
    end

    # FIXME set a max depth here to pretent unbounded recursion? probably should
    def find_node(node, type, first, last, depth: 0)
      child_nodes = node.children.select { |c| c.is_a?(RubyVM::AbstractSyntaxTree::Node) }
      #@logger.debug("D: #{depth} #{node.type} has #{child_nodes.size} children and spans #{node.first_lineno}:#{node.first_column} to #{node.last_lineno}:#{node.last_column}")

      if (node.type == type && first >= node.first_lineno && last <= node.last_lineno)
        return node
      end

      child_nodes.map { |n| find_node(n, type, first, last, depth: depth + 1) }.flatten
    end

    def find_lineage(target)
      lineage = _find_lineage(@root_node, target)
      lineage.pop # FIXME verify leafy node is equal to target or throw an error?
      lineage
    end

    def find_definition_namespace(target)
      lineage = find_lineage(target)

      namespaces = []
      lineage.each do |n|
        if n.type == :MODULE || n.type == :CLASS
          symbols = n.children.select { |c| c.is_a?(RubyVM::AbstractSyntaxTree::Node) && c.type == :COLON2 }
          if symbols.size != 1
            @logger.error("Couldn't determine symbol location for parent namespace")
          end
          symbol = symbols.first

          symstr = @source_lines[symbol.first_lineno - 1][symbol.first_column..symbol.last_column].strip
          namespaces << symstr
        end
      end

      return namespaces.join('::')
    end

    def find_definition_symbol(start_line, end_line)
      def_node = _find_definition_node(@root_node, start_line, end_line)
      def_column_start = def_node.first_column
      def_column_end = _find_args_start(def_node).first_column
      @source_lines[def_node.first_lineno - 1][(def_column_start + 3 + 1)..def_column_end].strip.to_sym
    end

    def find_definition_node(start_line, end_line)
      _find_definition_node(@root_node, start_line, end_line)
    end

    def _find_lineage(node, target, depth: 0)
      child_nodes = node.children.select { |c| c.is_a?(RubyVM::AbstractSyntaxTree::Node) }
      #@logger.debug("D: #{depth} #{node.type} has #{child_nodes.size} children and spans #{node.first_lineno}:#{node.first_column} to #{node.last_lineno}:#{node.last_column}")

      if (node.type == target.type &&

          target.first_lineno >= node.first_lineno &&
          target.last_lineno <= node.last_lineno)
        return [node]
      end

      parents = []
      child_nodes.each do |n|
        res = _find_lineage(n, target, depth: depth + 1)
        if !res.empty?
          res.unshift(n)
          parents = res
        end
      end

      return parents.flatten
    end

    # FIXME better error handling
    def _find_definition_node(node, start_line, end_line)
      defs = find_node(node, :DEFN, start_line, end_line)

      if defs.size > 1
        @logger.error("WHaaat? Multiple definitions found?! Bugs will probably follow")
      end
      defs.first
    end

    # FIXME better error handling
    def _find_args_start(def_node)
      args = find_node(def_node, :ARGS, def_node.first_lineno, def_node.first_lineno)

      if args.size > 1
        @logger.error("I didn't think this was possible, I must have been wrong")
      end
      args.first
    end

    def ruby_source(start_line, end_line)
      @source_lines[(start_line-1)..(end_line-1)].join()
    end

# This method is a litle weird and pretty deep into metaprogramming, so i'll try to explain it
#
# Given the source method some_method, and a range of lines to apply the breakpoint to, we will inject
# calls two breakpoint methods. We will pass these calls the string representation of the original source code.
# If the string of original source is part of the "handle" block, it will run withing the binding
# of the method up to that point, and allow for us to run our custom handler method to apply our debugging automation.
#
# Any remaining code in the method also needs to be eval'd, as we want it to be recognized in the original binding,
# and the same binding as we've used for evaluating our handler. This allows us to keep local variables persisted
# "between blocks", as we want our breakpoint code to have no impact to the original bindings and source code.
#
# A generated breakpoint is shown below, the resulting string. is what will be evaluated on the method
# that we will prepend to the original parent in order to initiate our override.
#
# def some_method
# local_bind=binding; ProductionBreakpoints.installed_breakpoints[:test_breakpoint_install].handle(local_bind) do
# <<-EOS
#       a = 1
#       sleep 0.5
#       b = a + 1
# EOS
# end
#  ProductionBreakpoints.installed_breakpoints[:test_breakpoint_install].finish(local_bind) do
# <<-EOS
# EOS
# end
#     end
#
# In this example, the entire body of the method has been wrapped in our handler.
# FIXME is there an elegant way to save the line number and file information here, and make
# it available to eval later? Would help to debug what is being eval'd
    def inject_metaprogramming_handlers(startstr, finish_str, def_start, def_end, start_line, end_line)
      source = @source_lines.dup
      source.insert(start_line - 1, "#{startstr} do\n<<-EOS\n") # FIXME columns? and indenting?
      source.insert(end_line + 1, "EOS\nend\n #{finish_str} do\n<<-EOS\n")
      source.insert(def_end + 1, "EOS\nend\n")
      source[(def_start-1)..(def_end + 2)].join()
    end
  end
end
