extends "res://mods/tales_of_movepack/status_effect_scripts/TO_Fof.gd"

#A single stack is three. More than that means the effect was applied twice.
func notify(node, id:String, args):
	if id == "turn_ending" || id == "turn_starting":
		check_field(node)

func added(node):
	.added(node)
	check_field(node)

func check_field(node):
	if node.amount > 3:
		transmute_field(node, status_effect_internal())

#Extended by subclasses
func status_effect_internal() -> StatusEffect:
	return null

func transmute_field(node, status_effect:StatusEffect):
	print(status_effect)
	node.fighter.status.add_effect(status_effect, 3)
	#remove partial field from args.target
	node.remove()
