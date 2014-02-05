require 'fake_sqs/collection_view'

describe FakeSQS::CollectionView do

  def wrap(collection)
    FakeSQS::CollectionView.new(collection)
  end

  it 'should correctly wrap an array' do
    array = %w{one two three four}
    view = wrap(array)
    view[0].should == 'one'
    view[1].should == 'two'
    view[2].should == 'three'
    view[3].should == 'four'
  end

  it 'should correctly wrap a hash' do
    hash = { :one => 1, :two => 2, :three => 3 }
    view = wrap(hash)
    view[:one].should == 1
    view[:two].should == 2
    view[:three].should == 3
  end

  it 'should respond to empty correctly' do
    wrap([]).should be_empty
    wrap({'one' => 1}).should_not be_empty
  end

  it 'should be enumerable' do
    result = wrap([1, 2, 3]).map { |i| i * i }
    result.should == [1, 4, 9]
  end

  it 'should respond to size/length' do
    wrap([1, 2, 3]).size.should == 3
    wrap([]).length.should == 0
  end

end