# frozen_string_literal: true

module ProductionBreakpoints

  class BreakpointMethodOverride

    # FINISH ME - add columns handling here
    def initialize(bp)
      handler_payload = bp.parser.get_injected_method_source_definition
      payload_offset = (bp.start_line - bp.node.first_lineno) - 1 # rubylines indexed by 1
      resume_offset = (bp.end_line - bp.node.first_lineno) - 1 # rubylines indexed by 1
      payload_size = bp.end_line - bp.start_line

        @unmodified_src = handler_payload.lines[0..payload_offset]
        @handler_src = handler_payload[payload_offset..payload_size]
        @resume_src = handler_payload[resume_offset..-1]

        @unmodified_src = RubyVM::InstructionSequence.compile(@unmodified_src)
        @handler_iseq = RubyVM::InstructionSequence.compile(@handler_src)
        @resume_iseq = RubyVM::InstructionSequence.compile(@resume_src)
    end
  end

  end
  # FIXME: this class is a mess, figure out interface and properly separate private / public
  class Parser
    attr_reader :root_node

    def initialize(source_file)
      @root_node = RubyVM::AbstractSyntaxTree.parse_file(source_file)
      @source_lines = File.read(source_file).lines
      @logger = ProductionBreakpoints.logger
    end

    def find_lineage(target)
      lineage = _find_lineage(@root_node, target)
      lineage.pop # FIXME: verify leafy node is equal to target or throw an error?
      lineage
    end

    def find_definition_namespace(target)
      lineage = find_lineage(target)

      namespaces = []
      lineage.each do |n|
        next unless n.type == :MODULE || n.type == :CLASS

        symbols = n.children.select { |c| c.is_a?(RubyVM::AbstractSyntaxTree::Node) && c.type == :COLON2 }
        if symbols.size != 1
          @logger.error("Couldn't determine symbol location for parent namespace")
        end
        symbol = symbols.first

        symstr = @source_lines[symbol.first_lineno - 1][symbol.first_column..symbol.last_column].strip
        namespaces << symstr
      end

      namespaces.join('::')
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

    def get_injected_method_source_definition
      @source_lines[(start_line - 1)..]
    end

    private

    def _find_lineage(node, target, depth: 0)
      child_nodes = node.children.select { |c| c.is_a?(RubyVM::AbstractSyntaxTree::Node) }
      # @logger.debug("D: #{depth} #{node.type} has #{child_nodes.size} children and spans #{node.first_lineno}:#{node.first_column} to #{node.last_lineno}:#{node.last_column}")

      if node.type == target.type &&

         target.first_lineno >= node.first_lineno &&
         target.last_lineno <= node.last_lineno
        return [node]
      end

      parents = []
      child_nodes.each do |n|
        res = _find_lineage(n, target, depth: depth + 1)
        unless res.empty?
          res.unshift(n)
          parents = res
        end
      end

      parents.flatten
    end

    # FIXME: better error handling
    def _find_definition_node(node, start_line, end_line)
      defs = find_node(node, :DEFN, start_line, end_line)

      if defs.size > 1
        @logger.error('WHaaat? Multiple definitions found?! Bugs will probably follow')
      end
      defs.first
    end

    # FIXME: better error handling
    def _find_args_start(def_node)
      args = find_node(def_node, :ARGS, def_node.first_lineno, def_node.first_lineno)

      if args.size > 1
        @logger.error("I didn't think this was possible, I must have been wrong")
      end
      args.first
    end


    # I think that it is fine that i've used recursion here, as I dont't think that the AST could possible have a loop.
    # The base case should terminate when the node is found, or error out if it is not
    # The case for it not found is not well tested and this error needs to be handled better
    # FIXME: set a max depth here to prevent unbounded recursion? probably should
    def find_node(node, type, first, last, depth: 0)
      child_nodes = node.children.select { |c| c.is_a?(RubyVM::AbstractSyntaxTree::Node) }
      # @logger.debug("D: #{depth} #{node.type} has #{child_nodes.size} children and spans #{node.first_lineno}:#{node.first_column} to #{node.last_lineno}:#{node.last_column}")

      if node.type == type && first >= node.first_lineno && last <= node.last_lineno
        return node
      end

      child_nodes.map { |n| find_node(n, type, first, last, depth: depth + 1) }.flatten
    end

  end
end
