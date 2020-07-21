RSpec.describe Arkswarm::StartupManager do

  before(:each) do
    @path = "#{__dir__}/testdata"
    @startup_contents = Arkswarm::ConfigLoader.parse_ini_file("#{@path}/startup_stuff.ini")
  end

  it 'Collects Startup FLAGS' do
    # Arkswarm.set_debug
    results = Arkswarm::StartupManager.collect_startup_flags(@startup_contents)
    expect(results['[startup_flags]']['keys']).to eq(['NoBattlEye', 'noundermeshkilling'])
  end

  it 'Collects Startup ARGS' do
    Arkswarm.set_cfg_value(:mods, [])
    results = Arkswarm::StartupManager.collect_startup_args(@startup_contents)
    expect(results['[startup_args]']['keys']).to eq(%w[PvEAllowStructuresAtSupplyDrops OverrideStructurePlatformPrevention OverrideOfficialDifficulty])
  end

  it 'Builds the startup command' do
    Arkswarm.set_fatal
    Arkswarm.set_cfg_value(:mods, [])
    gameuser = Arkswarm::ConfigLoader.parse_ini_file("#{@path}/small_gameuser.ini")
    Arkswarm::ConfigGen.set_ark_globals(gameuser)
    cmd = Arkswarm::StartupManager.build_startup_cmd(@startup_contents)
    expect(cmd).to eq('/server/ShooterGame/Binaries/Linux/ShooterGameServer TheIsland?listen?SessionName=Arkswarm?PvEAllowStructuresAtSupplyDrops=True?OverrideStructurePlatformPrevention=True?OverrideOfficialDifficulty=10 -NoBattlEye -noundermeshkilling')
  end
end
