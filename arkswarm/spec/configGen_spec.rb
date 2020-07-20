RSpec.describe Arkswarm::ConfigGen do

  before(:all) do
    @path = "#{__dir__}/testdata"
  end

  it 'Should merge configurations with similar values' do
    # Arkswarm.set_debug
    contents1 = Arkswarm::ConfigLoader.parse_ini_file("#{@path}/provided_config1.ini")
    contents2 = Arkswarm::ConfigLoader.parse_ini_file("#{@path}/provided_config2.ini")
    cfg_result = Arkswarm::ConfigGen.merge_config_by_type(:gameini, contents1, contents2)
    expect(cfg_result['[ServerSettings]']['keys']).to eq(["StructurePreventResourceRadiusMultiplier", "AllowRaidDinoFeeding", "ServerPVE"])
    expect(cfg_result['[ServerSettings]']['content']).to eq([["StructurePreventResourceRadiusMultiplier", "2.000000"], ["AllowRaidDinoFeeding", "False"], ["ServerPVE", "False"]])
  end

  it 'Should merge with different based on target config type :gameini' do
    # Arkswarm.set_debug
    contents1 = Arkswarm::ConfigLoader.parse_ini_file("#{@path}/provided_config1.ini")
    contents3 = Arkswarm::ConfigLoader.parse_ini_file("#{@path}/provided_config3.ini")
    cfg_result = Arkswarm::ConfigGen.merge_config_by_type(:gameini, contents1, contents3)
    expect(cfg_result.keys).to eq(["[ServerSettings]"])
    expect(cfg_result["[ServerSettings]"]["keys"]).to eq(["StructurePreventResourceRadiusMultiplier", "AllowRaidDinoFeeding"])
    expect(cfg_result["[ServerSettings]"]["content"]).to eq([["StructurePreventResourceRadiusMultiplier", "1.000000"], ["AllowRaidDinoFeeding", "False"]])
  end

  it 'Should merge with different based on target config type :game' do
    # Arkswarm.set_debug
    contents1 = Arkswarm::ConfigLoader.parse_ini_file("#{@path}/provided_config1.ini")
    contents3 = Arkswarm::ConfigLoader.parse_ini_file("#{@path}/provided_config3.ini")
    cfg_result = Arkswarm::ConfigGen.merge_config_by_type(:game, contents1, contents3)
    expect(cfg_result.keys).to eq(["[/Script/ShooterGame.ShooterGameMode]"])
    expect(cfg_result["[/Script/ShooterGame.ShooterGameMode]"]["keys"]).to eq(["OverridePlayerLevelEngramPoints", "bAllowUnlimitedRespecs"])
    expect(cfg_result["[/Script/ShooterGame.ShooterGameMode]"]["content"]).to eq([["OverridePlayerLevelEngramPoints", "2.000000"], ["bAllowUnlimitedRespecs", "False"]])
  end

  it 'Should merge configs with empty values, like config=' do
    # Arkswarm.set_debug
    contents1 = Arkswarm::ConfigLoader.parse_ini_file("#{@path}/provided_config1.ini")
    contents4 = Arkswarm::ConfigLoader.parse_ini_file("#{@path}/provided_config4.ini")
    cfg_result = Arkswarm::ConfigGen.merge_config_by_type(:gameini, contents1, contents4)
    expect(cfg_result.keys).to eq(["[ServerSettings]"])
    expect(cfg_result["[ServerSettings]"]["keys"]).to eq(["StructurePreventResourceRadiusMultiplier", "AllowRaidDinoFeeding", "RaiderProtection"])
    expect(cfg_result["[ServerSettings]"]["content"]).to eq([["StructurePreventResourceRadiusMultiplier", "1.000000"], ["AllowRaidDinoFeeding", "False"], ["RaiderProtection", ""]])
  end
end
