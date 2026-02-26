Config = Config or {}

-- System zużycia i napraw (Export dla skryptu mechanika)
-- Im lepszy silnik, tym wyższy mnożnik kosztów naprawy "core parts"
Config.EngineSwaps = {
    ['engine_v6'] = { 
        label = 'Silnik V6 Tuned', 
        soundName = 'ZENTORNO', 
        handlingMultiplier = 1.15, 
        repairMultiplier = 1.5 
    },
    ['engine_v8'] = { 
        label = 'Silnik V8 Supercharged', 
        soundName = 'DOMINATOR', 
        handlingMultiplier = 1.35, 
        repairMultiplier = 2.5 
    },
    ['engine_v12'] = { 
        label = 'Silnik V12 Hyper', 
        soundName = 'T20', 
        handlingMultiplier = 1.60, 
        repairMultiplier = 4.0 
    }
}

-- Itemizacja modyfikacji (Powiązanie z tgiann-inventory)
-- Wymagane przedmioty do zamontowania modyfikacji na pojeździe
Config.Items = {
    Tools = {
        Tablet = "tuner_tablet",
        RepairKit = "tuner_repairkit",
        EngineHoist = "tuner_enghoist"
    },
    Performance = {
        Engine = "mod_engine",
        Brakes = "mod_brakes",
        Transmission = "mod_transmission",
        Suspension = "mod_suspension",
        Armor = "mod_armor",
        Turbo = "mod_turbo"
    },
    Cosmetics = {
        Exhaust = "mod_exhaust",
        Extras = "mod_extras",
        Exterior = "mod_exterior",
        Interior = "mod_interior",
        Fender = "mod_fender",
        Frame = "mod_frame",
        FrontBumper = "mod_frontbumper",
        Grille = "mod_grille",
        Hood = "mod_hood",
        Horn = "mod_horn",
        Light = "mod_light",
        Livery = "mod_livery",
        Neon = "mod_neon",
        Plate = "mod_plate",
        RearBumper = "mod_rearbumper",
        Respray = "mod_respray",
        Rim = "mod_rim",
        Roof = "mod_roof",
        SideSkirt = "mod_sideskirt",
        Spoiler = "mod_spoiler",
        TyreSmoke = "mod_tyresmoke",
        WindowTint = "mod_windowtint"
    },
    Wheels = {
        Bulletproof = "mod_bullettires",
        Drift = "mod_drifttires",
        Stock = "mod_stocktires"
    }
}