# The dependency graph is stored as a Hash of (parent => Set<children>) pairs.
# Direct dependencies are added to a node by merging with that node's existing
# Set of dependencies.  The full list of dependencies of a node is generated
# by performing a depth-first search.

require 'set'

class Dependencies

  def initialize
    @graph = Hash.new { |h, k| h[k] = Set.new }
  end

  def size
    @graph.size
  end

  def add_direct(parent, children)
    @graph[parent].merge(children)

    # Make sure all children are initialized
    children.each { |c| @graph[c] }
  end

  def dependencies_for(node)
    dependencies = []
    visited = Set.new [node]
    to_visit = @graph[node].to_a

    while to_visit.length > 0
      current = to_visit.pop

      if visited.include? current
        next
      end

      visited.add(current)
      dependencies.push(current)

      # Append current node's children without creating additional array
      to_visit.push(*@graph[current])
    end

    dependencies.to_a.sort
  end

end

