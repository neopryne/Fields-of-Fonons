extends "res://mods/tales_of_movepack/battle_move_scripts/TO_GenericAttack.gd"

const DARK_FOF = "STATUS_FOF_DARK_NAME"
const EARTH_FOF = "STATUS_FOF_EARTH_NAME"
const AIR_FOF = "STATUS_FOF_AIR_NAME"
const WATER_FOF = "STATUS_FOF_WATER_NAME"
const FIRE_FOF = "STATUS_FOF_FIRE_NAME"
const LIGHT_FOF = "STATUS_FOF_LIGHT_NAME"
const DARK_FOF_PARTIAL = "STATUS_FOF_DARK_PARTIAL_NAME"
const EARTH_FOF_PARTIAL = "STATUS_FOF_EARTH_PARTIAL_NAME"
const AIR_FOF_PARTIAL = "STATUS_FOF_AIR_PARTIAL_NAME"
const WATER_FOF_PARTIAL = "STATUS_FOF_WATER_PARTIAL_NAME"
const FIRE_FOF_PARTIAL = "STATUS_FOF_FIRE_PARTIAL_NAME"
const LIGHT_FOF_PARTIAL = "STATUS_FOF_LIGHT_PARTIAL_NAME"

var rand = Random.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

#notify round end::whee!
func notify(fighter, id:String, args):
	if (id == "round_ending"):
		redistribute_fofs(fighter)

func redistribute_fofs(fighter):
	var toast = fighter.battle.create_toast()
	toast.setup_text(str("Give 'em the run around!"))
	fighter.battle.queue_play_toast(toast, fighter.slot)
	#print("fr redistro")
	var fofs = Array()
	var fighters = fighter.battle.get_fighters()
	for punchr in fighters:
		#print("fr punchr ", punchr)
		for effect_node in punchr.status.get_effects():
			var effect = effect_node.effect
			var effect_name = effect.get_name()
			#print("fr effect_name ", effect_name)
			#todo this should just be is TO_FOF
			match effect_name:
				DARK_FOF, EARTH_FOF, AIR_FOF, WATER_FOF, FIRE_FOF, LIGHT_FOF, DARK_FOF_PARTIAL, EARTH_FOF_PARTIAL, AIR_FOF_PARTIAL, WATER_FOF_PARTIAL, FIRE_FOF_PARTIAL, LIGHT_FOF_PARTIAL:
					fofs.push_back(effect_node)
					#punchr.status.remove_child(effect_node)
					#punchr.battle.queue_node_free(effect_node)
	for fof in fofs:
		#print("fr add back")
		var punchr = fighters[rand.rand_int(fighters.size())]
		#punchr.status.add_effect(fof, 3)#todo save status number?
		fof.transfer(punchr)

