RSpec.describe Arkswarm::ArkModManager do

  # it 'Stages downloaded mods' do
  #   Arkswarm::ArkModManager.copy_mods_to_staging_dir("#{__dir__}/testdata/mods/content/346110", "#{__dir__}/testdata/mods/ark_staged")
  # end

  it 'Stages downloaded mods', :this do
    Arkswarm.set_debug
    Arkswarm::ArkModManager.copy_mods_to_staging_dir("#{__dir__}/testdata/mods/content/346110", "#{__dir__}/testdata/mods/ark_staged")
    Arkswarm::ArkModManager.unpack_mods("#{__dir__}/testdata/mods/ark_staged")
  end
end
