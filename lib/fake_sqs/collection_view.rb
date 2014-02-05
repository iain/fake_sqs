require 'forwardable'

module FakeSQS
  class CollectionView
    include Enumerable
    extend Forwardable
    def_delegators :@original, :[], :each, :empty?, :size, :length

    UnmodifiableObjectError = Class.new(StandardError)

    def initialize( original )
      @original = original
    end

    def []=(key_or_index,value)
      raise UnmodifiableObjectError.new("This is a collection view and can not be modified - #{key_or_index} => #{value}")
    end

  end
end