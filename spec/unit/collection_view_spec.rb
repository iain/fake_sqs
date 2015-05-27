require 'fake_sqs/collection_view'

RSpec.describe FakeSQS::CollectionView do

  def wrap(collection)
    FakeSQS::CollectionView.new(collection)
  end

  it 'should correctly wrap an array' do
    array = %w{one two three four}
    view = wrap(array)
    expect(view[0]).to eq 'one'
    expect(view[1]).to eq 'two'
    expect(view[2]).to eq 'three'
    expect(view[3]).to eq 'four'
  end

  it 'should correctly wrap a hash' do
    hash = { :one => 1, :two => 2, :three => 3 }
    view = wrap(hash)
    expect(view[:one]).to eq 1
    expect(view[:two]).to eq 2
    expect(view[:three]).to eq 3
  end

  it 'should respond to empty correctly' do
    expect(wrap([])).to be_empty
    expect(wrap({'one' => 1})).to_not be_empty
  end

  it 'should be enumerable' do
    result = wrap([1, 2, 3]).map { |i| i * i }
    expect(result).to eq [1, 4, 9]
  end

  it 'should respond to size/length' do
    expect(wrap([1, 2, 3]).size).to eq 3
    expect(wrap([]).size).to eq 0
  end

end
