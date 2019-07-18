module ProductionBreakpoints
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

    def find_definition_symbol(start_line, end_line)
      def_node = _find_definition_node(@root_node, start_line, end_line)
      def_column_start = def_node.first_column
      def_column_end = _find_args_start(def_node).first_column
      @source_lines[def_node.first_lineno - 1][(def_column_start + 3 + 1)..def_column_end].strip.to_sym
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
  end
end
