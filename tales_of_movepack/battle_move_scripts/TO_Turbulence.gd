extends "res://mods/tales_of_movepack/battle_move_scripts/TO_GenericAttack.gd"

const air_wall = preload("res://data/status_effects/wall_air.tres")

var rand = Random.new()

func _execute(battle, user, _argument, attack_params):
	._execute(battle, user, _argument, attack_params)
	var fighters = battle.get_fighters()
	for fighter in fighters:
		if (rand.rand_int(4) == 0):
			fighter.status.add_effect(air_wall, 1)
