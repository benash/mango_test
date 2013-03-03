require './dependencies'
require 'test/unit'

class TestDependencies < Test::Unit::TestCase

  def setup
    @dep = Dependencies.new
  end

  def test_basic
    @dep.add_direct('A', %w{ B C } )
    @dep.add_direct('B', %w{ C E } )
    @dep.add_direct('C', %w{ G } )
    @dep.add_direct('D', %w{ A F } )
    @dep.add_direct('E', %w{ F } )
    @dep.add_direct('F', %w{ H } )

    assert_equal( %w{ B C E F G H }, @dep.dependencies_for('A'))
    assert_equal( %w{ C E F G H }, @dep.dependencies_for('B'))
    assert_equal( %w{ G }, @dep.dependencies_for('C'))
    assert_equal( %w{ A B C E F G H }, @dep.dependencies_for('D'))
    assert_equal( %w{ F H }, @dep.dependencies_for('E'))
    assert_equal( %w{ H }, @dep.dependencies_for('F'))
  end

  # This test exposed a bug where the parent node was listed as a dependency
  # of itself.  Adding the parent node to the visited list before iterating
  # fixed the bug.
  def test_circular_dependency
    @dep.add_direct('A', %w{ B })
    @dep.add_direct('B', %w{ C })
    @dep.add_direct('C', %w{ A })

    assert_equal( %w{ B C }, @dep.dependencies_for('A'))
  end

  def test_auto_create_children
    @dep.add_direct('A', %w{ B })

    assert_equal(2, @dep.size)
  end

  def test_self_dependency
    @dep.add_direct('A', %w{ A })

    assert_equal( [], @dep.dependencies_for('A'))
  end

  def test_empty_dependency
    @dep.add_direct('A', [])

    assert_equal( [], @dep.dependencies_for('A'))
  end

  # Creates a pseudorandom graph with a little under n nodes and a little over
  # n edges.
  #
  # Once the graph is created and residing in memory, calculating
  # dependencies happens fast.  However, too much memory is consumed to be
  # able to scale to 50 million nodes.  On my system, the test took 387MB for
  # a graph with 962811 nodes and 1333332 edges, which is around 177 bytes per
  # edge or node.  That's too much.  For a graph of 50 million nodes and
  # 100 million edges to fit into 8GB of memory, we need something closer to
  # 50 bytes per node or edge.
  #
  # We can cut the memory usage way down by using an array instead of a hash
  # to hold the data for each node.  We can assume the actual objects are
  # being stored in some sort of database.  Our array of nodes can then be
  # indexed by either the actual database row id of a node or an id that's
  # used just for this purpose (that's also stored in the database).  The
  # array cell would contain only a reference to another small dynamically-
  # sized array (like a C++ vector) that stores that node's direct
  # dependencies.
  #
  # Since the number of nodes is on the scale of millions, an id will fit in
  # a 32-bit integer, so that's 4 bytes per node.  The dynamic arrays that
  # hold the direct dependencies will be less memory efficient, maybe 8-16
  # bytes per edge.  Overall, this will be able to accomodate a 50 million-
  # node graph in memory.
  def test_large
    n = 1000000
    k = 2
    max_with_children = n * 2 / 3
    (0...max_with_children).each do |i|
      dependencies = k.times.collect { rand(n - i) + i }
      @dep.add_direct(i, dependencies)
    end

    puts "#{k * max_with_children} edges"
    puts "#{@dep.size} nodes"
  end

end

