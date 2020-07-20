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

  it "Should generate a contents tree with duplicatable keys that are different, not the same" do
    primary = Arkswarm::ConfigLoader.parse_ini_file("#{__dir__}/testdata/provided_dupe_allowed.ini")
    secondary = Arkswarm::ConfigLoader.parse_ini_file("#{__dir__}/testdata/provided_dupe_allowed2.ini")
    merged_configs = Arkswarm::ConfigLoader.merge_configs(primary, secondary)
    expect(merged_configs["[test]"]["content"].length).to eq(5)
  end
end
