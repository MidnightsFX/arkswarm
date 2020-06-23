RSpec.describe Arkswarm do

    it "Should be able to parse a file, write it back out and not mutate if not needed", :this do
        Arkswarm.set_fatal # set_debug
        path = "#{__dir__}/testdata"
        file = "test_arkmgr.cfg"
        contents_before = Arkswarm::ConfigLoader.parse_ini_file("#{path}/#{file}")
        expect(Arkswarm::FileManipulator).to receive(:ensure_file).with(path, file).and_return(true)
        Arkswarm::ConfigGen.gen_arkmanager_conf(path, file)
        contents_after = Arkswarm::ConfigLoader.parse_ini_file("#{path}/#{file}")
        contents_before.each do |key, values|
            expect(contents_before[key]["keys"]).to eq(contents_after[key]["keys"])
        end
        expect(contents_before['ungrouped']["content"]).to eq(contents_after['ungrouped']["content"])
    end
  end
  