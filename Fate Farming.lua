  --[[

  ****************************************
  *            Fate Farming              * 
  ****************************************

  Created by: Prawellp, sugarplum done updates v0.1.8 to v0.1.9, pot0to

  ***********
  * Version *
  *  1.1.14  *
  ***********

    -> 1.1.14   Update order of operations, removed random y
    -> 1.1.10   Merged random point in fate by scoobwrx
    -> 1.1.9    Fixed dismount upon arriving at fate issue, stops trying to mount if gets caught in 2-part fate
    -> 1.1.7    Fixed edge case when fate npc disappears on your way to talk to them
    -> 1.1.6    Fixed landing loop
    -> 1.1.4    Fixed check for (0,y,0) fates
    -> 1.1.1    Merged mount functions by CurlyWorm
    -> 1.0.0    Code changes
                    added pathing priority to prefer bonus fates -> most progress -> fate time left -> by distance
                    added map flag for next fate
                    added prioirity targeting for forlorns
                    added settings for:
                        - WaitIfBonusBuff
                        - MinTimeLeftToIgnoreFate
                        - JoinBossFatesIfActive
                        - CompletionToJoinBossFate
                    enabled non-collection fates that require interacting with an npc to start
                    [dev] rework of internal fate lists, aetheryte lists, character statuses
    -> 0.2.4    Code changes
                    added revive upon death (requires "teleport" to be set in the settings)
                    added GC turn ins
                Setting changes
                    added the category Retainer
                    added 2 new settings for it in the Retainer settings
                Plugin changes
                    added Deliveroo in Optional Plugins for turn ins


*********************
*  Required Plugins *
*********************

Plugins that are needed for it to work:

    -> Something Need Doing [Expanded Edition] : (Main Plugin for everything to work)   https://puni.sh/api/repository/croizat   
    -> VNavmesh :   (for Pathing/Moving)    https://puni.sh/api/repository/veyn       
    -> Pandora :    (for Fate targeting and auto sync [ChocoboS])   https://love.puni.sh/ment.json             
    -> RotationSolver Reborn :  (for Attacking enemys)  https://raw.githubusercontent.com/FFXIV-CombatReborn/CombatRebornRepo/main/pluginmaster.json       
        -> Target -> activate "Select only Fate targets in Fate" and "Target Fate priority"
        -> Target -> "Engage settings" set to "Previously engaged targets (enagegd on countdown timer)"

*********************
*  Optional Plugins *
*********************

This Plugins are Optional and not needed unless you have it enabled in the settings:

    -> Teleporter :  (for Teleporting to aetherytes [teleport][Exchange][Retainers])
    -> Lifestream :  (for chaning Instances [ChangeInstance][Exchange]) https://raw.githubusercontent.com/NightmareXIV/MyDalamudPlugins/main/pluginmaster.json
    -> AutoRetainer : (for Retainers [Retainers])   https://love.puni.sh/ment.json
    -> Deliveroo : (for gc turn ins [TurnIn])   https://plugins.carvel.li/
    -> Bossmod/BossModReborn: (for AI dodging)  https://puni.sh/api/repository/veyn
                                                https://raw.githubusercontent.com/FFXIV-CombatReborn/CombatRebornRepo/main/pluginmaster.json
    -> ChatCoordinates : (for setting a flag on the next Fate) available via base /xlplugins

]]
--[[

**************
*  Settings  *
**************
]]

--true = yes
--false = no

--Teleport and Voucher
EnableChangeInstance = true --should it Change Instance when there is no Fate (only works on DT fates)
ShouldExchange = false             --should it Exchange Vouchers
OldV = false                 --should it Exchange Old Vouchers

--Fate settings
WaitIfBonusBuff = true          --Don't change instances if you have the Twist of Fate bonus buff
CompletionToIgnoreFate = 90     --Percent above which to ignore fate
MinTimeLeftToIgnoreFate = 3*60  --Seconds below which to ignore fate
JoinBossFatesIfActive = true    --Join boss fates if someone is already working on it (to avoid soloing long boss fates). If false, avoid boss fates entirely.
CompletionToJoinBossFate = 0   --Percent above which to join boss fate
fatewait = 0                    --the amount how long it should when before dismounting (0 = at the beginning of the fate 3-5 = should be in the middle of the fate)
useBM = true                   --if you want to use the BossMod dodge/follow mode
BMorBMR = "BMR"

--Ranged attacks and spells max distance to be usable is 25.49y, 25.5 is "target out of range"
--Melee attacks (auto attacks) max distance is 2.59y, 2.60 is "target out of range"
--ranged and casters have a further max distance so not always running all way up to target
--users can adjust below settings to their liking
MeleeDist = 2.5                 --distance for BMRAI melee
RangedDist = 20                 --distance for BMRAI ranged

--Utilities
RepairAmount = 20          --the amount it needs to drop before Repairing (set it to 0 if you don't want it to repaier. onky supports self repair)
ExtractMateria = true      --should it Extract Materia
Food = "Moqueca <hq>"                  --Leave "" Blank if you don't want to use any food
                           --if its HQ include <hq> next to the name "Baked Eggplant <hq>"

--Retainer
Retainers = true           --should it do Retainers
TurnIn = false             --should it to Turn ins at the GC (requires Deliveroo)
slots = 5                  --how much inventory space before turning in

--Other stuff
ChocoboS = true                 --should it Activate the Chocobo settings in Pandora (to summon it)
MountToUse = "mount roulette"   --The mount you'd like to use when flying between fates, leave empty for mount roulette 

UsePandoraSync = true
--Change this value for how much echos u want in chat 
--2 is the fate your Moving to and Bicolor gems amount
--1 is only Bicolor gems
--0 is nothing
--echos will appear after it found a new fate 
  
--[[
  
************
*  Script  *
*   Start  *
************
  
]]
  
  ----------------------------------Settings----------------------------------------------

CharacterCondition = {
    dead=2,
    mounted=4,
    inCombat=26,
    casting=27,
    occupied31=31,
    occupied32=32,
    occupied=33,
    occupied39=39,
    transition=45,
    jumping=48,
    mounting=64,
    flying=77,
}


FatesData = {
    {
        zoneName = "Coerthas Central Highlands",
        zoneId = 155,
        aetheryteList = {
            { aetheryteName="Camp Dragonhead", x=223.98718, y=315.7854, z=-234.85168 }
        },
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            bossFates= {},
            blacklistedFates= {
            }
        }
    },
    {
        zoneName = "Coerthas Western Highlands",
        zoneId = 397,
        aetheryteList = {
            { aetheryteName="Falcon's Nest", x=474.87585, y=217.94458, z=708.5221 }
        },
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            bossFates= {},
            blacklistedFates= {
            }
        }
    },
    {
        zoneName = "Mor Dhona",
        zoneId = 156,
        aetheryteList = {
            { aetheryteName="Revenant's Toll", x=40.024292, y=24.002441, z=-668.0247 }
        },
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            bossFates= {},
            blacklistedFates= {
            }
        }
    },
    {
        zoneName = "The Sea of Clouds",
        zoneId = 401,
        aetheryteList = {
            { aetheryteName="Camp Cloudtop", x=-615.7473, y=-118.36426, z=546.5934 },
            { aetheryteName="Ok' Zundu", x=-613.1533, y=-49.485046, z=-415.03015 }
        },
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            bossFates= {},
            blacklistedFates= {
            }
        }
    },
    {
        zoneName = "Azys Lla",
        zoneId = 402,
        aetheryteList = {
            { aetheryteName="Helix", x=-722.8046, y=-182.29956, z=-593.40814 }
        },
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            bossFates= {},
            blacklistedFates= {
            }
        }
    },
    {
        zoneName = "The Dravanian Forelands",
        zoneId = 398,
        aetheryteList = {
            { aetheryteName="Tailfeather", x=532.6771, y=-48.722107, z=30.166992 },
            { aetheryteName="Anyx Trine", x=-304.12756, y=-16.70868, z=32.059082 }
        },
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            bossFates= {},
            blacklistedFates= {
            }
        }
    },
    {
        zoneName = "The Dravanian Hinterlands",
        zoneId=399,
        tpZoneId = 478,
        aetheryteList = {
            { aetheryteName="Idyllshire", x=71.94617, y=211.26111, z=-18.905945 }
        },
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            bossFates= {},
            blacklistedFates= {
            }
        }
    },
    {
        zoneName = "The Churning Mists",
        zoneId=400,
        aetheryteList = {
            { aetheryteName="Moghome", x=259.20496, y=-37.70508, z=596.85657 },
            { aetheryteName="Zenith", x=-584.9546, y=52.84192, z=313.43542 },
        },
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            bossFates= {},
            blacklistedFates= {
            }
        }
    },
    {
        zoneName = "Lakeland",
        zoneId = 813,
        aetheryteList = {
            { aetheryteName="The Ostall Imperative", x=-735, y=53, z=-230 },
            { aetheryteName="Fort Jobb", x=753, y=24, z=-28 },
        },
        fatesList= {
            collectionsFates= {
                "Pick-up Sticks",
            },
            otherNpcFates= {},
            bossFates= {
                "Calm a Chameleon",
                "A Beast among Men",
                "Draconian Measures",
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName = "Kholusia",
        zoneId = 814,
        aetheryteList = {
            { aetheryteName="Stilltide", x=668, y=29, z=289 },
            { aetheryteName="Wright", x=-244, y=20, z=385 },
            { aetheryteName="Tomra", x=-426, y=419, z=-623 },
        },
        fatesList= {
            collectionsFates= {
                "Ironbeard Builders - Rebuilt",
            },
            otherNpcFates= {},
            bossFates= {
                "Not Today (FATE)",
                "A Finale Most Formidable",
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName = "Amh Araeng",
        zoneId = 815,
        aetheryteList = {
            { aetheryteName="Mord Souq", x=246, y=12, z=-220 },
            { aetheryteName="Twine", x=-511, y=47, z=-212 },
            { aetheryteName="The Inn at Journey's Head", x=399, y=-24, z=307 },
        },
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            bossFates= {
                "Bayawak Attack",
                "The Elderblade",
                "The Odd Couple",
            },
            blacklistedFates= {
                "Tolba No. 1", -- pathing is really bad to enemies
            }
        }
    },
    {
        zoneName = "Il Mheg",
        zoneId = 816,
        aetheryteList = {
            { aetheryteName="Lydha Lran", x=-344, y=48, z=512 },
            { aetheryteName="Wolekdorf", x=380, y=87, z=-687 },
            { aetheryteName="Pla Enni", x=-72, y=103, z=-857 },
        },
        fatesList= {
            collectionsFates= {
                "Twice Upon a Time",
            },
            otherNpcFates= {
                { fateName= "Once Upon a Time", npcName= "Nectar-seeking Pixie" },
            },
            bossFates= {
                "Thrice Upon a Time",
                "Locus Terribilis",
                "Mad Magic",
                "Brute Fuath",
                "Breaking the Fuath Wall",
                "Go Fuath a Conqueror",
                "Fuath to Be Reckoned With",
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName = "The Rak'tika Greatwood",
        zoneId = 817,
        aetheryteList = {
            { aetheryteName="Slitherbough", x=-103, y=-19, z=297 },
            { aetheryteName="Fanow", x=382, y=21, z=-194 },
        },
        fatesList= {
            collectionsFates= {
                "Picking up the Pieces",
                "Pluck of the Draw",
                "Monkeying Around",
            },
            otherNpcFates= {
                { fateName= "Queen of the Harpies", npcName= "Fanow Huntress" },
            },
            bossFates= {
                "Attack of the Killer Tomatl",
                "I'll Be Bark",
                "Tojil War",
                "Tojil Annihilation",
                "Tojil Carnage",
                "Tojil Eclipse",
                "Attack the Block",
                "Queen of the Harpies",
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName = "The Tempest",
        zoneId = 818,
        aetheryteList = {
            { aetheryteName="The Ondo Cups", x=561, y=352, z=-199 },
            { aetheryteName="The Macarenses Angle", x=-141, y=-280, z=218 },
        },
        fatesList= {
            collectionsFates= {
                "Low Coral Fiber",
                "Pearls Apart",
            },
            otherNpcFates= {
                --{ fateName= "The Seashells He Sells", npcName= "Mewshs Laan" }, this is an escort fate
                { fateName= "Where has the Dagon", npcName= "Teushs Ooan" },
                { fateName= "Ondo of Blood", npcName= "Teushs Ooan" },
                { fateName= "Lookin' Back on the Track", npcName= "Teushs Ooan" },
            },
            bossFates= {
                "Ondo of Blood",
                "The Devil in the Deep Blue Sea",
                "The Head, the Tail, the Whole Damned Thing",
            },
            blacklistedFates= {
                "Coral Support", -- escort fate
                "The Seashells He Sells", -- escort fate
            }
        }
    },
    {
        zoneName = "Labyrinthos",
        zoneId = 956,
        aetheryteList = {
            { aetheryteName="The Archeion", x=443, y=170, z=-476 },
            { aetheryteName="Sharlayan Hamlet", x=8, y=-27, z=-46 },
            { aetheryteName="Aporia", x=-729, y=-27, z=302 },
        },
        fatesList= {
            collectionsFates= {
                "Sheaves on the Wind",
                "Moisture Farming",
            },
            otherNpcFates= {},
            bossFates= {
                "Let It Grow",
                "Incident Files: Steamed Vegetable",
                "The Frailty of Life",
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName = "Thavnair",
        zoneId = 957,
        aetheryteList = {
            { aetheryteName="Yedlihmad", x=193, y=6, z=629 },
            { aetheryteName="The Great Work", x=-527, y=4, z=36 },
            { aetheryteName="Palaka's Stand", x=405, y=5, z=-244 },
        },
        fatesList= {
            collectionsFates= {
                "Full Petal ALchemist: Perilous Pickings",
            },
            otherNpcFates= {},
            bossFates= {
                "The Accursed Kanabhuti",
                "Return of the Tyrant",
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName = "Garlemald",
        zoneId = 958,
        aetheryteList = {
            { aetheryteName="Camp Broken Glass", x=-408, y=24, z=479 },
            { aetheryteName="Tertium", x=518, y=-35, z=-178 },
        },
        fatesList= {
            collectionsFates= {
                "Parts Unknown",
            },
            otherNpcFates= {},
            bossFates= {
                "Artificial Malevolence: 15 Minutes to Comply",
                "Roses Are Red, Violence is Due",
                "Artificial Malevolence: Mighty Metatron",
                "The Man with the Golden Son",
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName = "Mare Lamentorum",
        zoneId = 959,
        aetheryteList = {
            { aetheryteName="Sinus Lacrimarum", x=-566, y=134, z=650 },
            { aetheryteName="Bestways Burrow", x=-0, y=-128, z=-512 },
        },
        fatesList= {
            collectionsFates= {
                "What a Thrill",
            },
            otherNpcFates= {
                { fateName= "Lepus Lamentorum: Dynamite Disaster", npcName= "Warringway" },
                { fateName= "Lepus Lamentorum: Cleaner Catastrophe", npcName= "Fallingway" },
            },
            bossFates= {
                "The Stones of Silence",
                "Lepus Lamentorum: Crazy Contraption",
                "Head Empty, Only Thoughts"
            },
            blacklistedFates= {
                "Hunger Strikes", --really bad line of sight with rocks, get stuck not doing anything quite often
            }
        }
    },
    {
        zoneName = "Ultima Thule",
        zoneId = 960,
        aetheryteList = {
            { aetheryteName="Reah Tahra", x=-544, y=74, z=269 },
            { aetheryteName="Abode of the Ea", x=64, y=272, z=-657 },
            { aetheryteName="Base omicron", x=-489, y=437, z=333 },
        },
        fatesList= {
            collectionsFates= {
                "Omicron Recall: Comms Expansion"
            },
            otherNpcFates= {
                { fateName= "Wings of Glory", npcName= "Ahl Ein's Kin" },
            },
            bossFates= {
                "Far from the Madding Horde",
                "Nevermore",
                "Omicron Recall: Killing Order",
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName = "Elpis",
        zoneId = 961,
        aetheryteList = {
            { aetheryteName="Anagnorisis", x=159, y=11, z=126 },
            { aetheryteName="The Twelve Wonders", x=-633, y=-19, z=542 },
            { aetheryteName="Poieten Oikos", x=-529, y=161, z=-222 },
        },
        fatesList= {
            collectionsFates= {
                "So Sorry, Sokles",
            },
            otherNpcFates= {
                { fateName="Grand Designs: Unknown Execution", npcName="Meletos the Inscrutable" },
                { fateName= "Grand Designs: Aigokeros", npcName= "Meletos the Inscrutable" },
                { fateName= "Nature's Staunch Protector", npcName= "Monoceros Monitor" },
            },
            bossFates= {
                "Grand Designs: Io",
                "The Rustling of Murderous Leaves",
                "Grand Designs: The Newest of New",
                "Eurydike: All Bark, No Bite",
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName = "Urqopacha",
        zoneId = 1187,
        aetheryteList = {
            { aetheryteName="Wachunpelo", x=335, y=-160, z=-415 },
            { aetheryteName="Worlar's Echo", x=465, y=115, z=635 },
        },
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {
                { fateName= "Pasture Expiration Date", npcName= "Tsivli Stoutstrider" },
                { fateName= "Gust Stop Already", npcName= "Mourning Yok Huy" },
                { fateName= "Lay Off the Horns", npcName= "Yok Huy Vigilkeeper" },
                { fateName= "Birds Up", npcName= "Coffee Farmer" },
                { fateName= "Salty Showdown", npcName= "Chirwagur Sabreur" },
                { fateName= "Fire Suppression", npcName= "Tsivli Stoutstrider" },
                --{ fateName= "Wolf Parade", npcName= "Pelupelu Peddler" }, -- two npcs with same name unfortunately
            },
            bossFates= {
                "Panaq Attack"
            },
            blacklistedFates= {
                "Young Volcanoes"
            }
        }
    },
    {
        zoneName="Kozama'uka",
        zoneId=1188,
        aetheryteList={
            { aetheryteName="Ok'hanu", x=-170, y=6, z=-470 },
            { aetheryteName="Many Fires", x=541, y=117, z=203 },
            { aetheryteName="Earthenshire", x=-477, y=124, z=311 }
        },
        fatesList={
            collectionsFates={
                "Borne on the Backs of Burrowers",
                "Combing the Area"
            },
            otherNpcFates= {},
            bossFates= {
                "Sayona Your Prayers"
            },
            blacklistedFates= {
                "Mole Patrol"
            }
        }
    },
    {
        zoneName="Yak T'el",
        zoneId=1189,
        aetheryteList={
            { aetheryteName="Iq Br'aax", x=-400, y=24, z=-431 },
            { aetheryteName="Mamook", x=720, y=-132, z=527 }
        },
        fatesList= {
            collectionsFates= {
                "Escape Shroom",
            },
            otherNpcFates= {
                --{ fateName= "Could've Found Something Bigger", npcName= "Xbr'aal Hunter" }, 2 npcs names same thing....
                { fateName= "Le Selva se lo Llevó", npcName= "Xbr'aal Hunter" },
                { fateName= "Stabbing Gutward", npcName= "Doppro Spearbrother" },
                --{ fateName= "Stick it to the Mantis", npcName= "Xbr'aal Sentry" }, -- 2 npcs named same thing.....
                { fateName= "Porting Is Such Sweet Sorrow", npcName= "Hoobigo Porter" },
            },
            bossFates= {
                "Moths are Tough"
            },
            blacklistedFates= {
                "The Departed",
            }
        }
    },
    {
        zoneName="Shaaloani",
        zoneId=1190,
        aetheryteList= {
            { aetheryteName="Hhusatahwi", x=390, y=0, z=465 },
            { aetheryteName="Sheshenewezi Springs", x=-295, y=19, z=-115 },
            { aetheryteName="Mehwahhetsoan", x=310, y=-15, z=-567 }
        },
        fatesList= {
            collectionsFates= {
                "Gonna Have Me Some Fur",
                "The Serpentlord Sires", -- Br'uk Vaw of the Setting Sun
            },
            otherNpcFates= {
                { fateName= "The Dead Never Die", npcName= "Tonawawtan Worker" },
                { fateName= "Ain't What I Herd", npcName= "Hhetsarro Herder" },
                { fateName= "Helms off to the Bull", npcName= "Hhetsarro Herder" },
                { fateName= "A Raptor Runs Through It", npcName= "Hhetsarro Angler" },
                { fateName= "The Serpentlord Suffers", npcName= "Br'uk Vaw of the Setting Sun" },
                { fateName= "That's Me and the Porter", npcName= " Pelupelu Peddler" },
            },
            bossFates= {
                "The Serpentlord Seethes",
                "Breaking the Jaw",
                "Helms off to the Bull", -- boss NPC fate, Hhetsarro Herder
                "The Dead Never Die", -- boss NPC fate, Tonawawtan Worker
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName="Heritage Found",
        zoneId=1191,
        aetheryteList= {
            { aetheryteName="Yyasulani Station", x=515, y=145, z=210 },
            { aetheryteName="The Outskirts", x=-221, y=32, z=-583 },
            { aetheryteName="Electrope Strike", x=-222, y=31, z=123 }
        },
        fatesList= {
            collectionsFates= {
                "License to Dill",
                "When It's So Salvage"
            },
            otherNpcFates= {
                { fateName= "It's Super Defective", npcName= "Novice Hunter" },
                { fateName= "Running of the Katobleps", npcName= "Novice Hunter" },
                { fateName= "Ware the Wolves", npcName= "Imperiled Hunter" },
                { fateName= "Domo Arigato", npcName= "Perplexed Reforger" },
                { fateName= "Old Stampeding Grounds", npcName= "Driftdowns Reforger" },
                { fateName= "Pulling the Wool", npcName= "Panicked Courier" }
            },
            bossFates= {
                "A Scythe to an Axe Fight",
                "(Got My Eye) Set on You"
            },
            blacklistedFates= {
                -- "Domo Arigato"
            }
        }
    },
    {
        zoneName="Living Memory",
        zoneId=1192,
        aetheryteList= {
            { aetheryteName="Leynode Mnemo", x=0, y=56, z=796 },
            { aetheryteName="Leynode Pyro", x=659, y=27, z=-285 },
            { aetheryteName="Leynode Aero", x=-253, y=56, z=-400 }
        },
        fatesList= {
            collectionsFates= {
                "Seeds of Tomorrow",
                "Scattered Memories"
            },
            otherNpcFates= {
                { fateName= "Canal Carnage", npcName= "Unlost Sentry GX" },
                { fateName= "Mascot March", npcName= "The Grand Marshal" }
            },
            bossFates= {
                "Feed Me, Sentries",
                "Slime to Die",
                "Critical Corruption",
                "Horse in the Round",
                "Mascot Murder"
            },
            blacklistedFates= {}
        }
    }
}

--Required Plugin Warning
if not HasPlugin("vnavmesh") then
    yield("/echo [FATE] Please Install vnavmesh")
end
if not HasPlugin("RotationSolverReborn") and not HasPlugin("RotationSolver") then
    yield("/echo [FATE] Please Install Rotation Solver Reborn")
end
if not HasPlugin("PandorasBox") then
    yield("/echo [FATE] Please Install Pandora's Box")
end

--Optional Plugin Warning
if EnableChangeInstance == true  then
    if HasPlugin("Lifestream") == false then
        yield("/echo [FATE] Please Install Lifestream or Disable ChangeInstance in the settings")
    end
end
if Retainers then
    if not HasPlugin("AutoRetainer") then
        yield("/echo [FATE] Please Install AutoRetainer")
    end
    if TurnIn then
        if not HasPlugin("Deliveroo") then
            yield("/echo [FATE] Please Install Deliveroo")
        end
    end
end
if ExtractMateria == true then
    if HasPlugin("YesAlready") == false then
        yield("/echo [FATE] Please Install YesAlready")
    end 
end   
if useBM == true then
    if HasPlugin("BossModReborn") == false and HasPlugin("BossMod") == false then
        yield("/echo [FATE] Please Install BossMod")
    else
        if HasPlugin("BossModReborn") then
            BMorBMR = "BMR"
        else
            BMorBMR = "BM"
        end
    end
end
if not HasPlugin("ChatCoordinates") then
    yield("/echo [FATE] ChatCoordinates is not installed. Map will not show flag when moving to next Fate.")
end

--Chocobo settings
if ChocoboS == true then
    PandoraSetFeatureState("Auto-Summon Chocobo", true) 
    PandoraSetFeatureConfigState("Auto-Summon Chocobo", "UseInCombat", true)
elseif ChocoboS == false then
    PandoraSetFeatureState("Auto-Summon Chocobo", false) 
    PandoraSetFeatureConfigState("Auto-Summon Chocobo", "UseInCombat", false)
end

--Fate settings
if UsePandoraSync then
    PandoraSetFeatureState("Auto-Sync FATEs", true)
else
    PandoraSetFeatureState("Auto-Sync FATEs", false)
end
PandoraSetFeatureState("FATE Targeting Mode", true)
PandoraSetFeatureState("Action Combat Targeting", false)
yield("/wait 0.5")

--snd property
function setSNDProperty(propertyName, value)
    local currentValue = GetSNDProperty(propertyName)
    if currentValue ~= value then
        SetSNDProperty(propertyName, tostring(value))
        LogInfo("[SetSNDProperty] " .. propertyName .. " set to " .. tostring(value))
    end
end

setSNDProperty("UseItemStructsVersion", true)
setSNDProperty("UseSNDTargeting", true)
setSNDProperty("StopMacroIfTargetNotFound", false)
setSNDProperty("StopMacroIfCantUseItem", false)
setSNDProperty("StopMacroIfItemNotFound", false)
setSNDProperty("StopMacroIfAddonNotFound", false)
setSNDProperty("StopMacroIfAddonNotVisible", false)

------------------------------Functions----------------------------------------------

function TeleportToClosestAetheryteToFate(playerPosition, nextFate)
    teleportTimePenalty = 50 -- to account for how long teleport takes you

    local aetheryteForClosestFate = nil
    local closestTravelDistance = GetDistanceToPoint(nextFate.x, nextFate.y, nextFate.z)
    LogInfo("[FATE] Direct flight distance is: "..closestTravelDistance)
    for j, aetheryte in ipairs(SelectedZone.aetheryteList) do
        local distanceAetheryteToFate = DistanceBetween(aetheryte.x, aetheryte.y, aetheryte.z, nextFate.x, nextFate.y, nextFate.z)
        local comparisonDistance = distanceAetheryteToFate + teleportTimePenalty
        LogInfo("[FATE] Distance via "..aetheryte.aetheryteName.." adjusted for tp penalty is "..tostring(comparisonDistance))

        if comparisonDistance < closestTravelDistance then
            LogInfo("[FATE] Updating closest aetheryte to "..aetheryte.aetheryteName)
            closestTravelDistance = comparisonDistance
            aetheryteForClosestFate = aetheryte
        end
    end

    if aetheryteForClosestFate ~=nil then
        TeleportTo(aetheryteForClosestFate.aetheryteName)
    end
end

--simple function to check a time limit
function timeout_check(start, length)
    if os.clock() - start > length then
        return true
    end
    return false
end

--Wrapper to dismount
function Dismount()
    local timeout_start = os.clock()
    local unable_to_dismount = false
    if PathIsRunning() or PathfindInProgress() then
        PathStop()
    end

    -- characters that are flying are also mounted
    if GetCharacterCondition(CharacterCondition.mounted) then
        repeat
            yield('/ac dismount')
            yield("/wait ".. 0.5)
            -- if still mounted after 10 seconds then stop trying
            if timeout_check(timeout_start,10) then
                unable_to_dismount = true
                break
            end
        until not GetCharacterCondition(CharacterCondition.mounted)
    end
    --teleport to reset position after unable to dismount to let the script continue
    if unable_to_dismount then
        TeleportTo(SelectedZone.aetheryteList[1].aetheryteName)
    end
end

function TeleportTo(aetheryteName)

    if not GetCharacterCondition(CharacterCondition.casting) and not GetCharacterCondition(CharacterCondition.transition) then
        yield("/tp "..aetheryteName)
    end
    yield("/wait 1") -- wait for casting to begin
    while GetCharacterCondition(CharacterCondition.casting) do
        LogInfo("[FATE] Casting teleport...")
        yield("/wait 1")
    end
    yield("/wait 1") -- wait for that microsecond in between the cast finishing and the transition beginning
    while GetCharacterCondition(CharacterCondition.transition) do
        LogInfo("[FATE] Teleporting...")
        yield("/wait 1")
    end
    yield("/wait 3")
end

function Mount()
    while not GetCharacterCondition(CharacterCondition.mounted) do
        if not IsPlayerCasting() and not GetCharacterCondition(CharacterCondition.mounting) then
            if MountToUse == "mount roulette" then
                yield('/gaction "mount roulette"')
            else
                yield('/mount "' .. MountToUse)
            end
        end
        yield("/wait ".. 1)
        HandleUnexpectedCombat()
    end
end

function HandleUnexpectedCombat()
    if GetCharacterCondition(CharacterCondition.inCombat) then
        TurnOnCombatMods()
    end
    
    while GetCharacterCondition(CharacterCondition.inCombat) do
        if not HasTarget() or GetTargetHP() <= 0 then
            yield("/battletarget")
        end
        yield("/wait 1")
        HandleDeath()
    end

    if not GetCharacterCondition(CharacterCondition.inCombat) then
        TurnOffCombatMods()
    end
end

function EorzeaTimeToUnixTime(eorzeaTime)
    return eorzeaTime/(144/7) -- 24h Eorzea Time equals 70min IRL
end

function GetFateNpcName(fateName)
    for i, fate in ipairs(SelectedZone.fatesList.otherNpcFates) do
        if fate.fateName == fateName then
            return fate.npcName
        end
    end
end

function IsCollectionsFate(fateName)
    for i, collectionsFate in ipairs(SelectedZone.fatesList.collectionsFates) do
        if collectionsFate == fateName then
            return true
        end
    end
    return false
end

function IsBossFate(fateName)
    for i, bossFate in ipairs(SelectedZone.fatesList.bossFates) do
        if bossFate == fateName then
            return true
        end
    end
    return false
end

function IsOtherNpcFate(fateName)
    for i, otherNpcFate in ipairs(SelectedZone.fatesList.otherNpcFates) do
        if otherNpcFate.fateName == fateName then
            return true
        end
    end
    return false
end

function IsBlacklistedFate(fateName)
    for i, blacklistedFate in ipairs(SelectedZone.fatesList.blacklistedFates) do
        if blacklistedFate == fateName then
            return true
        end
    end
    return false
end

--[[
    Given two fates, picks the better one based on priority progress -> is bonus -> time left -> distance
]]
function SelectNextFateHelper(tempFate, nextFate)
    if tempFate.timeLeft < MinTimeLeftToIgnoreFate or tempFate.progress > CompletionToIgnoreFate then
        return nextFate
    else
        if nextFate == nil then
                LogInfo("[FATE] Selecting #"..tempFate.fateId.." because no other options so far.")
                return tempFate
        -- elseif nextFate.startTime == 0 and tempFate.startTime > 0 then -- nextFate is an unopened npc fate
        --     LogInfo("[FATE] Selecting #"..tempFate.fateId.." because other fate #"..nextFate.fateId.." is an unopened npc fate.")
        --     return tempFate
        -- elseif tempFate.startTime == 0 and nextFate.startTime > 0 then -- tempFate is an unopened npc fate
        --     return nextFate
        else -- select based on progress
            if tempFate.progress > nextFate.progress then
                LogInfo("[FATE] Selecting #"..tempFate.fateId.." because other fate #"..nextFate.fateId.." has less progress.")
                return tempFate
            elseif tempFate.progress < nextFate.progress then
                LogInfo("[FATE] Selecting #"..nextFate.fateId.." because other fate #"..tempFate.fateId.." has less progress.")
                return nextFate
            elseif tempFate.progress == nextFate.progress then
                if nextFate.isBonusFate and tempFate.isBonusFate then
                    if tempFate.timeLeft < nextFate.timeLeft then -- select based on time left
                        LogInfo("[FATE] Selecting #"..tempFate.fateId.." because other fate #"..nextFate.fateId.." has more time left.")
                        return tempFate
                    elseif tempFate.timeLeft > nextFate.timeLeft then
                        LogInfo("[FATE] Selecting #"..tempFate.fateId.." because other fate #"..nextFate.fateId.." has more time left.")
                        return nextFate
                    elseif tempFate.timeLeft ==  nextFate.timeLeft then
                        tempFatePlayerDistance = GetDistanceToPoint(tempFate.x, tempFate.y, tempFate.z)
                        nextFatePlayerDistance = GetDistanceToPoint(nextFate.x, nextFate.y, nextFate.z)
                        if tempFatePlayerDistance < nextFatePlayerDistance then
                            LogInfo("[FATE] Selecting #"..tempFate.fateId.." because other fate #"..nextFate.fateId.." is farther.")
                            return tempFate
                        elseif tempFatePlayerDistance > nextFatePlayerDistance then
                            LogInfo("[FATE] Selecting #"..nextFate.fateId.." because other fate #"..nextFate.fateId.." is farther.")
                            return nextFate
                        else
                            if tempFate.fateId < nextFate.fateId then
                                return tempFate
                            else
                                return nextFate
                            end
                        end
                    end
                elseif nextFate.isBonusFate then
                    return nextFate
                elseif tempFate.isBonusFate then
                    return tempFate
                end
            end
        end
    end
    return nextFate
end

--Gets the Location of the next Fate. Prioritizes anything with progress above 0, then by shortest time left
function SelectNextFate()
    local fates = GetActiveFates()

    local nextFate = nil
    for i = 0, fates.Count-1 do
        local tempFate = {
            fateId = fates[i],
            fateEventItem = GetFateEventItem(fates[i]),
            fateIconId = GetFateIconId(fates[i]),
            fateLevel = GetFateLevel(fates[i]),
            fateMaxLevel = GetFateMaxLevel(fates[i]),
            fateChain = GetFateChain(fates[i]),
            fateName = GetFateName(fates[i]),
            progress = GetFateProgress(fates[i]),
            duration = GetFateDuration(fates[i]),
            startTime = GetFateStartTimeEpoch(fates[i]),
            x = GetFateLocationX(fates[i]),
            y = GetFateLocationY(fates[i]),
            z = GetFateLocationZ(fates[i]),
            isBonusFate = GetFateIsBonus(fates[i]),
        }
        tempFate.npcName = GetFateNpcName(tempFate.fateName)
        LogInfo("[FATE] Considering fate #"..tempFate.fateId.." "..tempFate.fateName)
        LogInfo("[FATE] Fate Event Item: "..tempFate.fateEventItem)

        local currentTime = EorzeaTimeToUnixTime(GetCurrentEorzeaTimestamp())
        if tempFate.startTime == 0 then
            tempFate.timeLeft = 900
        else
            tempFate.timeElapsed = currentTime - tempFate.startTime
            tempFate.timeLeft = tempFate.duration - tempFate.timeElapsed
        end
        LogInfo("[FATE] Time left on fate #:"..tempFate.fateId..": "..math.floor(tempFate.timeLeft//60).."min, "..math.floor(tempFate.timeLeft%60).."s")
        
        if not (tempFate.x == 0 and tempFate.z == 0) then -- sometimes game doesn't send the correct coords
            if IsCollectionsFate(tempFate.fateName) then -- skip collections fates
                LogInfo("[FATE] Skipping fate #"..tempFate.fateId.." "..tempFate.fateName.." due to being collections fate.")
            elseif not IsBlacklistedFate(tempFate.fateName) then -- check fate is not blacklisted for any reason
                if IsOtherNpcFate(tempFate.fateName) then
                    if tempFate.startTime > 0 then -- if someone already opened this fate, then treat is as all the other fates
                        nextFate = SelectNextFateHelper(tempFate, nextFate)
                    else -- no one has opened this fate yet
                        if nextFate == nil then -- pick this if there's nothing else
                            nextFate = tempFate
                        elseif tempFate.isBonusFate then
                            nextFate = SelectNextFateHelper(tempFate, nextFate)
                        elseif nextFate.startTime == 0 then -- both fates are unopened npc fates
                            nextFate = SelectNextFateHelper(tempFate, nextFate)
                        end
                    end
                elseif IsBossFate(tempFate.fateName) then
                    if JoinBossFatesIfActive and tempFate.progress >= CompletionToJoinBossFate then
                        nextFate = SelectNextFateHelper(tempFate, nextFate)
                    else
                        LogInfo("[FATE] Skipping fate #"..tempFate.fateId.." "..tempFate.fateName.." due to boss fate with not enough progress.")
                    end
                elseif tempFate.duration ~= 0 then -- else is normal fate. avoid unlisted talk to npc fates
                    nextFate = SelectNextFateHelper(tempFate, nextFate)
                end
                LogInfo("[FATE] Finished considering fate #"..tempFate.fateId.." "..tempFate.fateName)
            end
        end
    end

    LogInfo("[FATE] Finished considering all fates")

    if nextFate == nil then
        if not PathIsRunning() and not PathfindInProgress() then
            LogInfo("[FATE] No eligible fates found.")
            yield("/echo [FATE] No eligible fates found.")
        end
    else
        LogInfo("[FATE] Final selected fate #"..nextFate.fateId.." "..nextFate.fateName)
    end

    return nextFate
end

function random_direct()
    --math.random will return -1,0,1 so i'm working around it to get only a -1 or 1 by making a table
    local rng_dir = {-1,1}
    return rng_dir[math.random(1,2)]
end

--Paths to the Fate NPC Starter
function MoveToTarget(fate)
    LogInfo("MoveToTarget function")
    local meleetargdist = GetTargetHitboxRadius() + MeleeDist
    if HasTarget() and GetDistanceToTarget() > meleetargdist then
        local npc_x = GetTargetRawXPos() + (meleetargdist * random_direct())
        local npc_y = GetTargetRawYPos()
        local npc_z = GetTargetRawZPos() + (meleetargdist * random_direct())

        local xz_extent = 5
        local y_extent = 5
        local nearestLandX = QueryMeshNearestPointX(npc_x,npc_y,npc_z,xz_extent,y_extent)
        if nearestLandX == nil then
            nearestLandX = npc_x
        end

        local nearestLandZ = QueryMeshNearestPointZ(nearestLandX,npc_y,npc_z,xz_extent,y_extent)
        if nearestLandZ == nil then
            nearestLandZ = npc_z
        end
            --coffee farmer/ Birds up exception to land on the side of fence enemies spawn
            -- z -528 will be on right side of fence
            -- 84 or greater for Gust Stop Already
        if GetTargetName()==fate.npcName then
            if fate.fateName == "Birds Up" then
                nearestLandZ = QueryMeshNearestPointZ(nearestLandX,npc_y,-530,xz_extent,y_extent)
                if nearestLandZ == nil then
                    nearestLandZ = npc_z
                end
                repeat
                    nearestLandZ = QueryMeshNearestPointZ(nearestLandX,npc_y,-530,xz_extent,y_extent)
                    if nearestLandZ == nil then
                        nearestLandZ = npc_z
                    end
                until nearestLandZ <= -528
            elseif fate.fateName == "Gust Stop Already" then
                nearestLandZ = QueryMeshNearestPointZ(nearestLandX,npc_y,84,xz_extent,y_extent)
                if nearestLandZ == nil then
                    nearestLandZ = npc_z
                end
                repeat
                    nearestLandZ = QueryMeshNearestPointZ(nearestLandX,npc_y,84,xz_extent,y_extent)
                    if nearestLandZ == nil then
                        nearestLandZ = npc_z
                    end
                until nearestLandZ >= 84
            end
        end
        if GetCharacterCondition(CharacterCondition.flying) then
            npc_y = npc_y + 3
        end
        PathfindAndMoveTo(nearestLandX, npc_y, nearestLandZ, GetCharacterCondition(CharacterCondition.flying))
    end

end

--Paths to the Fate
function MoveToFate(nextFate)
    LogInfo("[FATE] Moving to fate #"..nextFate.fateId.." "..nextFate.fateName)
    yield("/echo [FATE] Moving to fate #"..nextFate.fateId.." "..nextFate.fateName)

    local angle = math.random() * 2 * math.pi
    local radius = GetFateRadius(nextFate.fateId)
    local randomX = nextFate.x + ((radius/2) * math.cos(angle))
    local randomY = nextFate.y + 15
    local randomZ = nextFate.z + ((radius/2) * math.sin(angle))

    LogInfo("[FATE] Math checks out")
    LogInfo("[FATE] Fate location: "..nextFate.x..", "..nextFate.y..", "..nextFate.z)
    LogInfo("[FATE] Random point: "..randomX..", "..randomY..", "..randomZ)

    -- fly towards middle, npc is going to be targeted and alter route anyway
    if IsOtherNpcFate(nextFate.fateName) and CurrentFate.startTime == 0  then
        randomX = nextFate.x
        randomY = nextFate.y
        randomZ = nextFate.z
    end

    local xz_extent = 25
    local y_extent = 5
    nearestLandX = QueryMeshNearestPointX(randomX, randomY, randomZ,xz_extent,y_extent)
    if nearestLandX == nil then
        nearestLandX = nextFate.x
        LogInfo("[FATE] nearestLandX set to fateX")
    else
        LogInfo("[FATE] nearestLandX is: "..nearestLandX)
    end
    nearestLandZ = QueryMeshNearestPointZ(nearestLandX,randomY,randomZ,xz_extent,y_extent)
    if nearestLandZ == nil then
        nearestLandZ = nextFate.z
        LogInfo("[FATE] nearestLandZ set to fateZ")
    else
        LogInfo("[FATE] nearestLandZ is: "..nearestLandZ)
    end
    nearestLandY = QueryMeshNearestPointY(nearestLandX,randomY,nearestLandZ,xz_extent,y_extent)
    if nearestLandY == nil then
        nearestLandY = randomY
        LogInfo("[FATE] nearestLandY set to randomY")
    else
        nearestLandY = nearestLandY + 15
        LogInfo("[FATE] nearestLandY is: "..nearestLandY)
    end

    LogInfo("[FATE] Queried nearest points")
    LogInfo("[FATE] Nearest points are: "..nearestLandX..", "..nearestLandY..", "..nearestLandZ)

    if HasPlugin("ChatCoordinates") then
        SetMapFlag(SelectedZone.zoneId, nearestLandX, nearestLandY, nearestLandZ)
    end

    LogInfo("[FATE] Generated random coordinates in fate: "..randomX..", "..randomY..", "..randomZ)

    local playerPosition = {
        x = GetPlayerRawXPos(),
        y = GetPlayerRawYPos(),
        z = GetPlayerRawZPos()
    }
    TeleportToClosestAetheryteToFate(playerPosition, nextFate)

    while not IsInFate() and not GetCharacterCondition(CharacterCondition.mounted) do
        HandleUnexpectedCombat()
        Mount()
        if GetCharacterCondition(CharacterCondition.mounted) and not GetCharacterCondition(CharacterCondition.flying) and HasFlightUnlocked(SelectedZone.zoneId) then
            yield("/gaction jump")
        end
    end

    if not IsInFate() then
        LogInfo("[FATE] Moving to "..nearestLandX..", "..nextFate.y..", "..nearestLandZ)
        PathStop()
        PathfindAndMoveTo(nearestLandX, randomY, nearestLandZ, HasFlightUnlocked(SelectedZone.zoneId))
    end
end

function IsFateActive(fateId)
    local activeFates = GetActiveFates()
    for i = 0, activeFates.Count-1 do
        if fateId == activeFates[i] then
            return true
        end
    end
    return false
end

function InteractWithFateNpc(fate)
    while not IsInFate() and IsFateActive(fate.fateId) and CurrentFate.startTime == 0 do

        HandleUnexpectedCombat()

        if not IsFateActive(fate.fateId) or CurrentFate.startTime ~= 0 then
            break
        end
        
        -- if target is already selected earlier during pathing, avoids having to target and move again
        while (not HasTarget() or GetTargetName()~=fate.npcName) and not IsInFate() and IsFateActive(fate.fateId) and CurrentFate.startTime == 0 do
            yield("/echo [FATE] Searching for NPC target")
            LogInfo("[FATE] Searching for NPC target")
            yield("/target "..fate.npcName)
            if HasTarget() and not PathIsRunning() and not PathfindInProgress() and GetDistanceToTarget() > GetTargetHitboxRadius() + 5 then
                MoveToTarget(fate)
            end
        end

        while HasTarget() and GetTargetName()==fate.npcName and not IsInFate() and IsFateActive(fate.fateId) and CurrentFate.startTime == 0 do -- break conditions in case someone snipes the interact before you
            LogInfo("[FATE] Inside interact Loop")
            if not PathIsRunning() and not PathfindInProgress() and GetDistanceToTarget() > GetTargetHitboxRadius() + 5 then
                LogInfo("[FATE] NPC too far away executing MoveToTarget")
                MoveToTarget(fate)
            end
            if not IsAddonVisible("Talk") and not IsAddonVisible("SelectYesno") and not IsInFate() and IsFateActive(fate.fateId) and not PathIsRunning() then
                LogInfo("[FATE] Inside talk to npc")
                yield("/target "..fate.npcName)
                yield("/wait 1")
                yield("/interact")
                yield("/wait 1")
                while GetCharacterCondition(CharacterCondition.occupied32) do
                    LogInfo("Occupied by NPC")
                    if IsAddonVisible("Talk") then
                        yield("/click Talk Click")
                    elseif IsAddonVisible("SelectYesno") then
                        yield("/callback SelectYesno true 0")
                    end
                    yield("/wait 0.5")
                end
                yield("/wait 1") -- wait to register
                while GetTargetName() == fate.npcName do
                    LogInfo("Attempting to clear target.")
                    ClearTarget()
                    yield("/wait 1")
                end
            end
            yield("/wait 1")
        end
        yield("/wait 1")
    end
    yield("/wait 1")
    if not IsLevelSync() and GetPlayerLevel() > fate.fateMaxLevel then
        yield("/lsync") -- there's a milisecond between when the fate starts and the lsync command becomes available, so Pandora's lsync won't trigger
    end
    LogInfo("[FATE] Exiting InteractWithFateNpc")
end

--Paths to the enemy (for Meele)
function EnemyPathing()
    while GetDistanceToTarget() > 3.5 do
        local enemy_x = GetTargetRawXPos()
        local enemy_y = GetTargetRawYPos()
        local enemy_z = GetTargetRawZPos()
        if PathIsRunning() == false then
            PathfindAndMoveTo(enemy_x, enemy_y, enemy_z)
        end
        yield("/wait 0.1")
    end
end

--When there is no Fate 
function ChangeInstance()
    --Change Instance
    while GetCharacterCondition(CharacterCondition.inCombat) or GetCharacterCondition(CharacterCondition.transition) do
        yield("/wait 1")
    end
    
    if EnableChangeInstance then
        yield("/wait 1")

        yield("/target aetheryte")
        yield("/wait 1")

        while not HasTarget() or GetTargetName() ~= "aetheryte" do
            LogInfo("[FATE] Attempting to target aetheryte.")
            local closestAetheryte = nil
            local closestAetheryteDistance = math.maxinteger
            for i, aetheryte in ipairs(SelectedZone.aetheryteList) do
                -- GetDistanceToPoint is implemented with raw distance instead of distance squared
                local distanceToAetheryte = GetDistanceToPoint(aetheryte.x, aetheryte.y, aetheryte.z)
                if distanceToAetheryte < closestAetheryteDistance then
                    closestAetheryte = aetheryte
                    closestAetheryteDistance = distanceToAetheryte
                end
            end
            TeleportTo(closestAetheryte.aetheryteName)

            yield("/target Aetheryte")
            yield("/wait 1")
        end

        if GetCharacterCondition(CharacterCondition.mounted) then
            LogInfo("[FATE] Dismounting...")
            Dismount()
        end

        yield("/lockon")
        yield("/automove")
        while GetDistanceToTarget() > 10 do
            LogInfo("[FATE] Approaching aetheryte...")
            yield("/wait 0.5")
        end
        yield("/automove off")

        local nextInstance = (GetZoneInstance() % 3) + 1

        yield("/li "..nextInstance) -- start instance transfer
        yield("/wait 1") -- wait for instance transfer to register
        while GetCharacterCondition(CharacterCondition.transition) do -- wait for instance transfer to complete
            LogInfo("[FATE] Waiting for instance transfer to complete...")
            yield("/wait 1")
        end
        yield("/lockon off")
    end
    yield("/wait 3")
end

function RangedJob()
    local ClassJob = GetClassJobId()

    if ClassJob == 5 or ClassJob == 23 or -- Archer/Bard
        ClassJob == 6 or ClassJob == 24 or -- Conjurer/White Mage
        ClassJob == 7 or ClassJob == 25 or -- Thaumaturge/Black Mage
        ClassJob == 26 or ClassJob == 27 or ClassJob == 28 or -- Arcanist/Summoner/Scholar
        ClassJob == 31 or -- Machinist
        ClassJob == 33 or -- Astrologian
        ClassJob == 35 or -- Red Mage
        ClassJob == 38 or -- Dancer
        ClassJob == 40 or -- Sage
        ClassJob == 42 then -- Pictomancer
        return true
    else
        return false
    end
end

function TurnOnCombatMods()
    -- turn on RSR in case you have the RSR 30 second out of combat timer set
    yield("/rotation manual")
    Class = GetClassJobId()
    
    --[[
    if Class == 21 or Class == 37 or Class == 19 or Class == 32 or Class == 24 then -- white mage holy OP, or tank classes
        yield("/rotation settings aoetype 2") -- aoe
    else
        yield("/rotation settings aoetype 1") -- cleave
    end
    --]]
    yield("/rotation settings aoetype 2")

    if not bossModAIActive and useBM then

        local MaxDistance = MeleeDist --default to melee distance
        --ranged and casters have a further max distance so not always running all way up to target
        if RangedJob() then
            MaxDistance = RangedDist
        end

        if BMorBMR == "BMR" then
            yield("/bmrai on")
            yield("/bmrai followtarget on")
            yield("/bmrai followcombat on")
            yield("/bmrai followoutofcombat on")
            yield("/bmrai maxdistancetarget " .. MaxDistance)
        else
            yield("/vbmai on")
            --yield("/vbmai followtarget on")
            --yield("/vbmai followcombat on")
            --yield("/vbmai followoutofcombat on")
        end
        bossModAIActive = true
    end
end

function TurnOffCombatMods()
    -- no need to turn RSR off

    -- turn of BMR so you don't start engaging other mobs
    if useBM and bossModAIActive then
        if BMorBMR == "BMR" then
            yield("/bmrai off")
            yield("/bmrai followtarget off")
            yield("/bmrai followcombat off")
            yield("/bmrai followoutofcombat off")
        else
            yield("/vbmai off")
            --yield("/vbmai followtarget off")
            --yield("/vbmai followcombat off")
            --yield("/vbmai followoutofcombat off")
        end
        bossModAIActive = false
    end
end

function antistuck()
    LogInfo("[FATE] Entered antistuck")
    stuck = 0
    PX = GetPlayerRawXPos()
    PY = GetPlayerRawYPos()
    PZ = GetPlayerRawZPos()
    yield("/wait 3")
    PXX = GetPlayerRawXPos()
    PYY = GetPlayerRawYPos()
    PZZ = GetPlayerRawZPos()

    local AntiStuckDist = MeleeDist-- default to melee distance

    if RangedJob() then
        AntiStuckDist = RangedDist -- max distance for ranged to attack is 25.5
    end

    if PX == PXX and PY == PYY and PZ == PZZ then
        if HasTarget() then
            -- noticed melee jobs tend to dance around if the antistuck distance is same as the melee distance so giving it 1.5y flex
            while GetDistanceToTarget() > AntiStuckDist + 1.5 and stuck < 20 do
                LogInfo("[FATE] Looping antistuck")

                if not PathIsRunning() then
                    local enemy_x = GetTargetRawXPos() + (AntiStuckDist * random_direct())
                    local enemy_y = GetTargetRawYPos()
                    local enemy_z = GetTargetRawZPos() + (AntiStuckDist * random_direct())

                    local nearestX = QueryMeshNearestPointX(enemy_x,enemy_y,enemy_z,5,5)
                    if nearestX == nil then
                        nearestX = enemy_x
                    end

                    local nearestZ = QueryMeshNearestPointZ(enemy_x,enemy_y,enemy_z,5,5)
                    if nearestZ == nil then
                        nearestZ = nearestZ
                    end

                    LogInfo("[FATE] Moving to enemy "..nearestX..", "..enemy_y..", "..nearestZ)
                    PathStop()
                    yield("/wait 1")
                    PathfindAndMoveTo(nearestX, enemy_y, nearestZ, GetCharacterCondition(CharacterCondition.flying))
                end
                yield("/wait 0.5")
                stuck = stuck + 1
            end
            if stuck >= 20 then
                PathStop()
                yield("/wait 1")
            end
            stuck = 0
        end
    end
end

function HandleDeath()
    if GetCharacterCondition(CharacterCondition.dead) then --Condition Dead
        yield("/echo [FATE] You have died. Returning to home aetheryte.")
        while not IsAddonVisible("SelectYesno") do --rez addon wait
            yield("/wait 1")
        end

        if IsAddonVisible("SelectYesno") then --rez addon yes
            yield("/callback SelectYesno true 0")
            yield("/wait 0.1")
        end

        while GetCharacterCondition(CharacterCondition.casting) or GetCharacterCondition(CharacterCondition.transition) do --wait between areas
            yield("/wait 1")
        end

        while GetCharacterCondition(CharacterCondition.dead) do --wait till alive
            yield("/wait 1")
        end

        while not IsInZone(SelectedZone.zoneId) do
            TeleportTo(SelectedZone.aetheryteList[1].aetheryteName)
        end
    end
end

function PurchaseBicolorVouchers(bicolorGemCount)
    local npcName = ""
    if ShouldExchange and bicolorGemCount >= 1400 then
        if not PathIsRunning() or not PathfindInProgress() then
            if OldV then
                if not IsInZone(962) then
                    TeleportTo("Old Sharlayan")
                end
                PathfindAndMoveTo(74.17, 5.15, -37.44)
                npcName = "Gadfrid"
            else
                if not IsInZone(1186) then
                    TeleportTo("Solution Nine")
                end
                yield("/wait 1")
                yield("/li Nexus Arcade")
                yield("/wait 5") -- lifestream takes a second to initiate
                while GetCharacterCondition(CharacterCondition.transition) or GetCharacterCondition(CharacterCondition.occupied32) do
                    yield("/wait 1")
                end
                PathfindAndMoveTo(-198.466, 0.922, -6.955)
                npcName = "Beryl"
            end
        end
        
        while not HasTarget() or GetTargetName() ~= npcName or (GetTargetName() == npcName and GetDistanceToTarget() > 5) do
            yield("/target "..npcName)
            yield("/wait 1")
        end
        PathStop()
        yield("/interact")
        yield("/wait 1")
        while not IsAddonVisible("ShopExchangeCurrency") do
            yield("/click Talk Click")
            yield("/wait 1")
        end
        yield("/callback ShopExchangeCurrency false 0 5 "..(bicolorGemCount//100)) --Change the last number to the amount you want to buy. Change the third number "5" to the item you want to buy (the first item will be 0 then 1, 2, 3 and so on )
        while not IsAddonVisible("SelectYesno") do
            yield("/wait 1")
        end
        yield("/callback SelectYesno true 0")
        while IsAddonVisible("SelectYesno") do
            yield("/wait 1")
        end
        while GetCharacterCondition(CharacterCondition.occupied32) do
            yield("/callback ShopExchangeCurrency true -1")
            yield("/wait 1")
        end
    end
end

---------------------------Beginning of the Code------------------------------------

--vnavmesh building
if not NavIsReady() then
    yield("/echo [FATE] Building Mesh Please wait...")
end
while not NavIsReady() do
    yield("/wait 1")
end
if NavIsReady() then
    yield("/echo [FATE] Mesh is Ready!")
end

GemAnnouncementLock = false
AvailableFateCount = 0
FoodCheck = 0

local selectedZoneId = GetZoneID()
for i, zone in ipairs(FatesData) do
    if selectedZoneId == zone.zoneId then
        SelectedZone = zone
    end
end
if SelectedZone == nil then
    yield("/echo [FATE] Current zone is only partially supported. Will not teleport back on death or leaving.")
    SelectedZone = {
        zoneName = "Unknown Zone Name",
        zoneId = selectedZoneId,
        aetheryteList = {},
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            bossFates= {},
            blacklistedFates= {
            }
        }
    }
end

LastTeleportTimeStamp = 0

--Start of the Loop

LogInfo("[FATE] Starting fate farming script.")

while true do
    LogInfo("[FATE] Starting new iteration.")
    while not IsInZone(SelectedZone.zoneId) do
        local teleport = SelectedZone.aetheryteList[1].aetheryteName
        yield("/echo [FATE] Teleporting to "..teleport.." and resuming FATE farm.")
        TeleportTo(teleport)
    end
    
    ---------------------------Select and Move to Fate--------------------------------------
    ---TargetClosestEnemy(distance value)
    ---GetTargetFateID() - returns 0 if not fate target

    CurrentFate = SelectNextFate() -- init first fate object

    -- if has twist of fate buff, stay in current instance and search for more fates
    -- while loop allows you to click off the buff
    while CurrentFate == nil and WaitIfBonusBuff and (HasStatusId(1288) or HasStatusId(1289)) do
        LogInfo("[FATE] Staying in instance due to Twist of Fate buff.")
        yield("/echo [FATE] Staying in instance due to Twist of Fate bonus buff.")
        yield("/wait 30")
        CurrentFate = SelectNextFate()
    end
    while CurrentFate == nil do
        if EnableChangeInstance and GetZoneInstance() > 0 then
            LogInfo("[FATE] Changing instances.")
            ChangeInstance()
        else
            yield("/wait 10")
        end
        CurrentFate = SelectNextFate()
    end
    
    MoveToFate(CurrentFate)

    HandleDeath()

    ---------------------------- While vnavmesh is Moving ------------------------------

    local fateNPCNav = false
    local fateEnemyNav = false
    -- while vnavmesh is moving to a fate
    while (PathIsRunning() or PathfindInProgress()) and not IsInFate() do
        
        -- if mounted on land, jump to fly
        if GetCharacterCondition(CharacterCondition.mounted) and not GetCharacterCondition(CharacterCondition.flying) and HasFlightUnlocked(SelectedZone.zoneId) then 
            yield("/gaction jump")
            yield("/wait 0.3")
        end

        if IsOtherNpcFate(CurrentFate.fateName) and CurrentFate.startTime == 0 and GetDistanceToPoint(CurrentFate.x, CurrentFate.y, CurrentFate.z) <= 75 + GetFateRadius(CurrentFate.fateId) and not fateNPCNav then
            yield("/target "..CurrentFate.npcName)
            if HasTarget() and GetTargetName()==CurrentFate.npcName then
                --PathStop()
                MoveToTarget(CurrentFate)
                fateNPCNav = true
            end
        elseif GetDistanceToPoint(CurrentFate.x, CurrentFate.y, CurrentFate.z) <= 75 + GetFateRadius(CurrentFate.fateId) and not fateEnemyNav then
            LogInfo("[Fate] Targeting closest enemey")
            TargetClosestEnemy(75)
            LogInfo("[Fate] Fate target ID: "..GetTargetFateID())
            if HasTarget() and GetTargetFateID() > 0 then
                --PathStop()
                MoveToTarget(CurrentFate)
                fateEnemyNav = true
            end
        end

        --Stops Moving to dead Fates or change paths to better fates
        NextFate = SelectNextFate()
        if NextFate~=nil and CurrentFate.fateId ~= NextFate.fateId then
            yield("/echo [FATE] Stopped pathing to #"..CurrentFate.fateId.." "..CurrentFate.fateName..", higher priority fate found: #"..NextFate.fateId.." "..NextFate.fateName)
            PathStop()
            CurrentFate = NextFate
            if not PathIsRunning() then
                MoveToFate(CurrentFate)
            end
        end

        yield("/wait 1")
    end

    local timeout_start = os.clock()
    --wait for path to complete
    while (IsInFate() or (IsOtherNpcFate(CurrentFate.fateName) and CurrentFate.startTime == 0)) and
          (PathIsRunning() or PathfindInProgress())
    do
        yield("/wait 0.1")
        if IsOtherNpcFate(CurrentFate.fateName) and CurrentFate.startTime == 0 and GetDistanceToPoint(CurrentFate.x, CurrentFate.y, CurrentFate.z) <= 75 + GetFateRadius(CurrentFate.fateId) and not fateNPCNav then
            yield("/target "..CurrentFate.npcName)
            if HasTarget() and GetTargetName()==CurrentFate.npcName then
                --PathStop()
                MoveToTarget(CurrentFate)
                fateNPCNav = true
            end
        elseif IsInFate() and not fateEnemyNav then
            LogInfo("[Fate] Targeting closest enemey")
            TargetClosestEnemy(75)
            LogInfo("[Fate] Fate target ID: "..GetTargetFateID())
            if HasTarget() and GetTargetFateID() > 0 then
                --PathStop()
                MoveToTarget(CurrentFate)
                fateEnemyNav = true
            end
        end
        if timeout_check(timeout_start,10) then
            PathStop()
            break
        end
    end

    --Dismount
    if GetCharacterCondition(CharacterCondition.mounted) then
        Dismount()
    end

    -- need to talk to npc to start fate
    if IsOtherNpcFate(CurrentFate.fateName) and CurrentFate.startTime == 0 then
        InteractWithFateNpc(CurrentFate)
    else
        if not UsePandoraSync and not IsLevelSync() and GetPlayerLevel() > CurrentFate.fateMaxLevel then
            yield("/lsync")
        end
    end

    -------------------------------Engage Fate Combat--------------------------------------------
    bossModAIActive = false

    if IsInFate() then
        --Activates Bossmod upon landing in a fate
        TurnOnCombatMods()
    end
    while IsInFate() do
        GemAnnouncementLock = false
    
        if GetCharacterCondition(CharacterCondition.mounted) then
            Dismount()
        end

        --Paths to enemys when Bossmod is disabled
        if not useBM then
            EnemyPathing()
            PathStop()
        end
        AvailableFateCount = 0
        
        --antistuck()

        if GetCharacterCondition(CharacterCondition.dead) then
            HandleDeath()
        end

        -- switches to targeting forlorns for bonus (if present)
        if not HasTarget() or (HasTarget() and GetTargetName() ~= 'Forlorn Maiden' and GetTargetName() ~= 'The Forlorn') then
            yield("/target Forlorn Maiden")
            yield("/target The Forlorn")
        end
        yield("/wait 1")
    end

    --Disables bossmod when the fate is over
    if not IsInFate() then
        TurnOffCombatMods()
    end

    -----------------------------After Fate------------------------------------------
    HandleUnexpectedCombat()

    --food usage
    if not (GetCharacterCondition(CharacterCondition.casting) or GetCharacterCondition(CharacterCondition.transition)) then
        if not HasStatusId(CharacterCondition.jumping) and (Food == "" == false) and FoodCheck <= 10 and not GetCharacterCondition(CharacterCondition.casting) and not GetCharacterCondition(CharacterCondition.transition) then
            while not HasStatusId(CharacterCondition.jumping) and (Food == "" == false) and FoodCheck <= 10 and not GetCharacterCondition(CharacterCondition.casting) and not GetCharacterCondition(CharacterCondition.transition) do
                while GetCharacterCondition(CharacterCondition.casting) or GetCharacterCondition(CharacterCondition.transition) do
                    yield("/wait 1")
                end
                yield("/item " .. Food)
                yield("/wait 2")
                FoodCheck = FoodCheck + 1
            end
            if FoodCheck >= 10 then
                yield("/echo [FATE] no Food left <se.1>")
            end
            if HasStatusId(48) then
                FoodCheck = 0
            end
        end
    end

    --Repair function
    if RepairAmount > 0 and not GetCharacterCondition(CharacterCondition.mounted) and not GetCharacterCondition(CharacterCondition.inCombat) then
        if NeedsRepair(RepairAmount) then
            while not IsAddonVisible("Repair") do
                LogInfo("[FATE] Opening repair menu...")
                yield("/generalaction repair")
                yield("/wait 0.5")
            end
            yield("/callback Repair true 0")
            yield("/wait 0.1")
            if IsAddonVisible("SelectYesno") then
                yield("/callback SelectYesno true 0")
                yield("/wait 0.1")
            end
            while GetCharacterCondition(CharacterCondition.occupied39) do
                LogInfo("[FATE] Repairing...")
                yield("/wait 1") 
            end
            yield("/wait 1")
            yield("/callback Repair true -1")
        end
    end

    --Materia Extraction function
    if ExtractMateria and not GetCharacterCondition(CharacterCondition.mounted) and not GetCharacterCondition(CharacterCondition.inCombat) then
        if CanExtractMateria(100) then
            yield("/generalaction \"Materia Extraction\"")
            yield("/waitaddon Materialize")
            while CanExtractMateria(100) == true and GetInventoryFreeSlotCount() > 1 and not GetCharacterCondition(CharacterCondition.inCombat) do
                LogInfo("[FATE] Extracting materia...")
                if not IsAddonVisible("Materialize") then
                    yield("/generalaction \"Materia Extraction\"")
                    yield("/wait 0.5")
                end
                while not IsAddonVisible("Materialize") do
                    yield("/wait 0.5")
                end
                yield("/pcall Materialize true 2")
                yield("/wait 0.5")
                if IsAddonVisible("MaterializeDialog") then
                    yield("/pcall MaterializeDialog true 0")
                    yield("/wait 0.1")
                end
                while GetCharacterCondition(39) do
                    yield("/wait 0.5")
                end
            end 
            yield("/wait 1")
            yield("/pcall Materialize true -1")
            yield("/echo [FATE] Extracted all materia")
            yield("/wait 1")
        end
    end

    if CanExtractMateria(100) and Extract and not GetCharacterCondition(CharacterCondition.casting) then
        yield("/generalaction \"Materia Extraction\"")
        yield("/waitaddon Materialize")
        while CanExtractMateria(100) == true and not GetCharacterCondition(CharacterCondition.casting) and GetInventoryFreeSlotCount() > 1 do
            LogInfo("[FATE] Extracting materia 2...")
            if not IsAddonVisible("Materialize") then
                yield("/generalaction \"Materia Extraction\"")
            end
                yield("/pcall Materialize true 2")
                yield("/wait 0.5")
            if IsAddonVisible("MaterializeDialog") then
                yield("/pcall MaterializeDialog true 0")
                yield("/wait 0.1")
            end
            while GetCharacterCondition(39) do
                yield("/wait 0.5")
            end
        end 
        yield("/wait 1")
        yield("/pcall Materialize true -1")
        yield("/echo [FATE] Extracted all materia")
        yield("/wait 1")
    end

    --Retainer Process
    if Retainers and not GetCharacterCondition(CharacterCondition.inCombat) and
       (not WaitIfBonusBuff or not (HasStatusId(1288) or HasStatusId(1289))) then
        LogInfo("[FATE] Handling retainers...")
        if ARRetainersWaitingToBeProcessed() == true then
            while not IsInZone(129) do
                TeleportTo("Limsa Lominsa Lower Decks")
            end
            while IsPlayerAvailable() == false and NavIsReady() == false do
                yield("/wait 1")
            end
            if IsPlayerAvailable() and NavIsReady() then
                PathfindAndMoveTo(-122.7251, 18.0000, 20.3941)
                yield("/wait 1")
            end
            while PathIsRunning() or PathfindInProgress() do
                yield("/wait 1")
            end
            if PathIsRunning() == false or PathfindInProgress() == false then
                PathfindAndMoveTo(-122.7251, 18.0000, 20.3941)
                yield("/wait 1")
            end
            yield("/target Summoning Bell")
            while GetTargetName() == "" do
            yield("/target Summoning Bell")
            end 
            while GetTargetName() == "Summoning Bell" and GetDistanceToTarget() > 4.5 do
                PathfindAndMoveTo(-122.7251, 18.0000, 20.3941)
                yield("/wait 1")
                while PathIsRunning() or PathfindInProgress() do
                    yield("/wait 1")
                end
            end
            if GetTargetName() == "Summoning Bell" and GetDistanceToTarget() <= 4.5 then
            yield("/wait 0.5")
            yield("/interact")
            if IsAddonVisible("RetainerList") then
            yield("/ays e")
            yield("/echo [FATE] Processing retainers")
            yield("/wait 1")
            end
            end
        
            while ARRetainersWaitingToBeProcessed() do
                yield("/wait 1")
            end

            yield("/wait 1")
            yield("/waitaddon RetainerList")
            yield("/echo [FATE] Finished processing retainers")
            yield("/wait 1")
            yield("/callback RetainerList true -1")
            yield("/wait 1")
            while IsAddonVisible("RetainerList") do
                yield("/callback RetainerList true -1")
                yield("/wait 1")
            end

            --Deliveroo
            if TurnIn and HasPlugin("Deliveroo") then
                if GetInventoryFreeSlotCount() < slots and TurnIn == true then
                    yield("/li gc")
                end
                while DeliverooIsTurnInRunning() == false do
                    yield("/wait 1")
                    yield("/deliveroo enable")
                end
                if DeliverooIsTurnInRunning() then
                    PathStop()
                end
                while DeliverooIsTurnInRunning() do
                    yield("/wait 1")
                end
            end
        end
    end


    ---------------------------Notification tab--------------------------------------
    local bicolorGemCount = GetItemCount(26807)
    if not GemAnnouncementLock then
        GemAnnouncementLock = true
        if bicolorGemCount > 1400 then
            yield("/echo [FATE] You're almost capped with "..tostring(bicolorGemCount).."/1500 gems! <se.3>")
            yield("/wait 1")
        else
            yield("/echo [FATE] Gems: "..tostring(bicolorGemCount).."/1500")
        end
    end
    PurchaseBicolorVouchers(bicolorGemCount)
end
