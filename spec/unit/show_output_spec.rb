require 'fake_sqs/show_output'

describe FakeSQS::ShowOutput do

  after do
    $stdout = STDOUT
  end

  it "outputs the result of rack app" do
    app = double :app
    $stdout = StringIO.new
    middleware = FakeSQS::ShowOutput.new(app)
    env = {"rack.input" => ""}
    app.should_receive(:call).with(env).and_return([200, {}, ["<xml>"]])

    middleware.call(env)

    $stdout.rewind
    $stdout.read.should eq "--- {}\n\n<xml>\n"
  end

end
