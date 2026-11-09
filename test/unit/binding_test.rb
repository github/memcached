
require File.expand_path("#{File.dirname(__FILE__)}/../test_helper")
require 'objspace'

class BindingTest < Test::Unit::TestCase
  def test_libmemcached_loaded
    Warning.expects(:warn).with(regexp_matches(/constant ::Rlibmemcached is deprecated/), optionally(anything))
    Rlibmemcached
  end

  def test_struct_allocation_uses_typed_data
    lib = Memcached.const_get(:Lib)
    [lib::MemcachedAnalysisSt, lib::MemcachedStatSt, lib::MemcachedSt,
     lib::MemcachedResultSt, lib::MemcachedServerSt].each do |klass|
      assert_match(/"struct":\s*"SWIG pointer"/, ObjectSpace.dump(klass.allocate))
    end

    analysis = lib::MemcachedAnalysisSt.new
    analysis.pool_hit_ratio = 0.5
    assert_equal 0.5, analysis.pool_hit_ratio
  end

  def test_owned_and_borrowed_pointers_survive_garbage_collection
    lib = Memcached.const_get(:Lib)
    client = lib.memcached_create(nil)
    lib.memcached_server_add(client, 'localhost', 11211)
    clone = lib.memcached_clone(nil, client)
    assert_match(/"struct":\s*"SWIG pointer"/, ObjectSpace.dump(client))

    3.times do
      server = lib.memcached_select_server_at(clone, 0)
      assert_match(/"struct":\s*"SWIG pointer"/, ObjectSpace.dump(server))
      assert_equal 'localhost', server.hostname
      server = nil
      GC.start
    end

    assert_equal 11211, lib.memcached_select_server_at(clone, 0).port
    assert_equal 11211, lib.memcached_select_server_at(client, 0).port
  end

  def test_disowning_preserves_the_native_pointer
    lib = Memcached.const_get(:Lib)
    result = lib::MemcachedResultSt.new
    result.root = lib.memcached_create(nil)
    GC.start

    root = result.root
    root.last_server_key = 7
    assert_equal 7, result.root.last_server_key
  ensure
    lib.memcached_free(root) if root
  end

  def test_pointer_conversion_rejects_unrelated_objects
    lib = Memcached.const_get(:Lib)
    [Object.new, Time.now, lib::MemcachedAnalysisSt.new].each do |object|
      assert_raise(TypeError) { lib.memcached_clone(nil, object) }
    end
  end
end
