require 'logger'

module Arkswarm
  # Helps ensure that messages are sent as they are generated not on completion of command
  $stdout.sync = true

  VERSION = "0.1.0"

  GAMEINI_MONIKER= ['game', 'gameini', 'game.ini'].freeze
  GAMEUSERSETTINGSINI_MONIKER= ['gameuser', 'gameuser', 'gameusersetting', 'gameusersettings', 'gameusersettings.ini'].freeze
  DUPLICATABLE_KEYS = %w(ConfigOverrideItemMaxQuantity LevelExperienceRampOverrides HarvestResourceItemAmountClassMultipliers DinoClassDamageMultipliers TamedDinoClassDamageMultipliers DinoClassResistanceMultipliers 
     ConfigOverrideItemCraftingCosts TamedDinoClassResistanceMultipliers ConfigOverrideSupplyCrateItems EngramEntryAutoUnlocks OverrideEngramEntries OverrideNamedEngramEntries 
     ConfigAddNPCSpawnEntriesContainer ConfigSubtractNPCSpawnEntriesContainer ConfigOverrideNPCSpawnEntriesContainer DinoSpawnWeightMultipliers)

  LOG = Logger.new(STDOUT)
  LOG.level = Logger::INFO

  def self.set_debug
    Arkswarm::LOG.level = Logger::DEBUG
  end

  def self.set_fatal # For testing purposes, no logging
    Arkswarm::LOG.level = Logger::FATAL
  end
end
