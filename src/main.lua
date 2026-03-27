local mods = rom.mods
mods['SGG_Modding-ENVY'].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods['SGG_Modding-ModUtil']
chalk = mods['SGG_Modding-Chalk']
reload = mods['SGG_Modding-ReLoad']
local lib = mods['adamant-ModpackLib']

config = chalk.auto('config.lua')
public.config = config

local _, revert = lib.createBackupSystem()

-- =============================================================================
-- MODULE DEFINITION
-- =============================================================================

public.definition = {
    id       = "KBMEscapeAlt",
    name     = "Fixing Escape Behavior for KBM",
    category = "QoL",
    group    = "QoL",
    tooltip  = "KBM Escape will now work during boon/pom Selection, Hex selection, PoS menu, and during death sequences.",
    default  = true,
    dataMutation = false,
    modpack = "h2-modpack",
}

-- =============================================================================
-- MODULE LOGIC
-- =============================================================================

local function apply()
end

local function registerHooks()
    modutil.mod.Path.Wrap("IsPauseBlocked", function(base)
        if not lib.isEnabled(config, public.definition.modpack) then return base() end

        if SessionMapState.HandlingDeath then
            return false
        end
        if SessionMapState.BlockPause then
            return true
        end

        if CurrentRun ~= nil then
            if CurrentRun.Hero.FishingStarted then
                return true
            end
        end

        local excludedScreens = { UpgradeChoice = true, SpellScreen = true, TalentScreen = true }
        for screenName, screen in pairs(ActiveScreens) do
            if excludedScreens[screenName] then
                return false
            end
            if screen.BlockPause then
                return true
            end
        end

        local blockingScreens = {
            "Codex", "MetaUpgrade", "ShrineUpgrade", "MusicPlayer",
            "QuestLog", "Mutator", "GhostAdmin", "AwardMenu", "RunClear",
            "RunHistory", "GameStats", "TraitTrayScreen", "WeaponUpgradeScreen",
            "InventoryScreen", "MarketScreen", "WeaponShop",
            "DebugEnemySpawn", "DebugConversations",
        }
        for _, name in pairs(blockingScreens) do
            if ActiveScreens[name] then
                return true
            end
        end

        return false
    end)
end

-- =============================================================================
-- Wiring
-- =============================================================================

public.definition.apply = apply
public.definition.revert = revert

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(function()
        import_as_fallback(rom.game)
        registerHooks()
        if lib.isEnabled(config, public.definition.modpack) then apply() end
        if public.definition.dataMutation and not lib.isCoordinated(public.definition.modpack) then
            SetupRunData()
        end
    end)
end)

local uiCallback = lib.standaloneUI(public.definition, config, apply, revert)
rom.gui.add_to_menu_bar(uiCallback)
