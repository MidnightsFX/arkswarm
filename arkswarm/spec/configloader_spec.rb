RSpec.describe Arkswarm::ConfigLoader do

    it "Should load all of the sections of an example file" do
        file_contents = Arkswarm::ConfigLoader.parse_ini_file("#{__dir__}/testdata/example_gameuser.ini")
        expect(file_contents.keys.include?("[/Script/ShooterGame.ShooterGameUserSettings]")).to be true
        expect(file_contents.keys.include?("[ScalabilityGroups]")).to be true
        expect(file_contents.keys.include?("[SessionSettings]")).to be true
        expect(file_contents.keys.include?("[/Script/Engine.GameSession]")).to be true
        expect(file_contents.keys.include?("[Player.Info]")).to be true
        expect(file_contents.keys.include?("[ServerSettings]")).to be true
        expect(file_contents.keys.include?("[/Game/Mods/AE/TestGameMode_AE.TestGameMode_AE_C]")).to be true
        expect(file_contents.keys.include?("[/Game/PrimalEarth/CoreBlueprints/TestGameMode.TestGameMode_C]")).to be true
        expect(file_contents.keys.include?("[ARK_Additions_Brachiosaurus]")).to be true
        expect(file_contents.keys.include?("[AwesomeSpyGlass]")).to be true
        expect(file_contents.keys.include?("[Shiny]")).to be true
        expect(file_contents.keys.include?("[RareSightings]")).to be true
    end

    it "Should load all of the key/values for a section under that respective section" do
        file_contents = Arkswarm::ConfigLoader.parse_ini_file("#{__dir__}/testdata/example_gameuser.ini")
        expect(file_contents["[RareSightings]"]["content"].length).to eq(5)
    end

    it "Should load all of the key/values for a unsectioned file" do
        file_contents = Arkswarm::ConfigLoader.parse_ini_file("#{__dir__}/testdata/small_arkmgr.cfg")
        # puts "#{file_contents["ungrouped"]["content"]}"
        expect(file_contents["ungrouped"]["content"].length).to eq(6)
        generated_contents = Arkswarm::ConfigLoader.generate_config_file(file_contents)
        expect(generated_contents.length).to eq(10)
    end
  end
  