# Fields-of-Fonons
Cassette Beasts mod that adds the field of fonons system from Tales of the Abyss as well as some moves from it.

This mod edits the battle controller with [ModUtils'](https://github.com/Yukitty/CassetteBeasts-modutils) class patcher to add feilds of fonons to existing attacks, and cause FOF changes when using certain moves.

The FOF effects can be toggled in settings.

### Requirements:
ModUtils

## FOF Change table
In order of trigger move, and then Earth, Wind, Water, Fire fofs.
```
	add_fof_change("MOVE_SMACK_NAME", "MOVE_COAL_STORY_NAME", "MOVE_ZEPHYR_NAME", "TO_MOVE_SPLASH_NAME", "MOVE_SUPERHEATED_FIST_NAME")
	add_fof_change("MOVE_SPIT_NAME", "MOVE_COAL_STORY_NAME", "MOVE_ZEPHYR_NAME", "TO_MOVE_SPLASH_NAME", "MOVE_INFLAME_NAME")
	add_fof_change("MOVE_WALLOP_NAME", "", "", "", "MOVE_SUPERHEATED_FIST_NAME")
	add_fof_change("MOVE_TOY_HAMMER_NAME", "", "", "TO_MOVE_FROZEN_HAMMER_NAME", "")
	add_fof_change("TO_MOVE_FIRST_AID_NAME", "", "", "MOVE_MEDITATE_NAME", "")
	add_fof_change("MOVE_ENERGY_SHOT_NAME", "TO_MOVE_ENERGY_BLAST_NAME", "TO_MOVE_ENERGY_BLAST_NAME", "TO_MOVE_ENERGY_BLAST_NAME", "TO_MOVE_ENERGY_BLAST_NAME")
	add_fof_change("TO_MOVE_ENERGY_BLAST_NAME", "", "TO_MOVE_PHOTON_NAME", "", "MOVE_RADIATION_BREATH_NAME")
	add_fof_change("MOVE_COAL_STORY_NAME", "MOVE_MOUNTAIN_SMASH_NAME", "MOVE_SANDSTORM_NAME", "", "MOVE_INFLAME_NAME")#close to default earth
	add_fof_change("MOVE_SCORCH_NAME", "MOVE_COAL_STORY_NAME", "", "", "MOVE_INFLAME_NAME")
	add_fof_change("TO_MOVE_SPLASH_NAME", "TO_MOVE_ICICLE_RAIN_NAME", "MOVE_HURRICANE_NAME", "MOVE_TORRENT_NAME", "MOVE_BOIL_NAME")#todo this is default for water moves
	add_fof_change("TO_MOVE_TURBULENCE_NAME", "", "MOVE_HURRICANE_NAME", "", "TO_MOVE_FLARE_TORNADO_NAME")
	add_fof_change("TO_MOVE_STALAGMITE_NAME", "MOVE_MOUNTAIN_SMASH_NAME", "", "", "TO_MOVE_ERUPTION_NAME")
	add_fof_change("TO_MOVE_FLAME_BURST_NAME", "MOVE_INCINERATE_NAME", "TO_MOVE_EXPLOSION_NAME", "MOVE_BOIL_NAME", "")
	add_fof_change("MOVE_TRICK_NAME", "MOVE_REVOLVING_DOOR_NAME", "MOVE_GLITTER_BOMB_NAME", "MOVE_STICKER_TRICK_NAME", "MOVE_HOT_POTATO_NAME")
	add_fof_change("MOVE_TREAT_NAME", "MOVE_TREASURE_DIG_NAME", "MOVE_PUMPKIN_PIE_NAME", "MOVE_BAD_JOKE_NAME", "MOVE_BE_RANDOM_NAME")
	add_fof_change("MOVE_BUTTERFLY_EFFECT_NAME", "MOVE_CRUMBLE_NAME", "MOVE_HURRICANE_NAME", "MOVE_AVALANCHE_NAME", "MOVE_IONIZED_AIR_NAME")
	add_fof_change("MOVE_WINK_NAME", "MOVE_STONY_LOOK_NAME", "", "", "")
	add_fof_change("MOVE_SANDSTORM_NAME", "", "", "", "MOVE_GLASS_CANNON_NAME")
	add_fof_change("MOVE_AVALANCHE_NAME", "", "MOVE_FOG_NAME", "TO_MOVE_ICICLE_RAIN_NAME", "MOVE_FOG_NAME")
	add_fof_change("MOVE_ZEPHYR_NAME", "MOVE_SANDSTORM_NAME", "MOVE_SONIC_BOOM_NAME", "MOVE_FOG_NAME", "TO_MOVE_ENERGY_BLAST_NAME")
	add_fof_change("MOVE_LIGHTNING_BOLT_NAME", "MOVE_IRON_FILINGS_NAME", "MOVE_THUNDER_BLAST_NAME", "", "")
	add_fof_change("MOVE_SHOOTING_STAR_NAME", "MOVE_METEOR_BARRAGE_NAME", "", "", "")
	add_fof_change("MOVE_ELEMENTAL_WALL_NAME", "MOVE_EARTH_WALL_NAME", "MOVE_WIND_WALL_NAME", "MOVE_WATER_WALL_NAME", "MOVE_FIRE_WALL_NAME")
	add_fof_change("MOVE_BAD_FORECAST_NAME", "MOVE_SANDSTORM_NAME", "MOVE_THUNDER_BLAST_NAME", "MOVE_BLIZZARD_NAME", "MOVE_SCORCH_NAME")
	add_fof_change("MOVE_HYPNOTISE_NAME", "MOVE_WONDERFUL_7_NAME", "MOVE_WONDERFUL_7_NAME", "MOVE_WONDERFUL_7_NAME", "MOVE_WONDERFUL_7_NAME")
```

## Attribution
All original mod assets, scripts, and edits are published under MIT license

Project structure from [Synergy is Fun](https://github.com/TheOnly8Z/CassetteBeasts_SynergyIsFun)

Cassette Beasts is developed by Bytten Studio and published by Raw Fury.