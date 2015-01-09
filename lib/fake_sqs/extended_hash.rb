require 'deep_merge'

module FakeSQS
  module ExtendedHash
    def dotted_to_nested_hash
      self.map do |dotted_key, value|
        dotted_key.split('.').reverse.inject(value) do |v, k|
          {k => v}
        end
      end.inject(&:deep_merge)
    end
  end
end

class Hash
  include FakeSQS::ExtendedHash
end
