extends StatusEffect

const MdefUp = preload("res://data/status_effects/stat_mdef_up.tres")
const Multistrike = preload("res://data/status_effects/multistrike.tres")
const MatkUp = preload("res://data/status_effects/stat_matk_up.tres")
const EvaUp = preload("res://data/status_effects/stat_evasion_up.tres")
const Multiattack = preload("res://data/status_effects/multitarget.tres")
const RatkUp = preload("res://data/status_effects/stat_ratk_up.tres")
const RdefUp = preload("res://data/status_effects/stat_rdef_up.tres")
const MindMeld = preload("res://data/status_effects/mind_meld.tres")
const HealingSteam = preload("res://data/status_effects/healing_steam.tres")
const ParryStance = preload("res://data/status_effects/parry_stance.tres")
const AccUp = preload("res://data/status_effects/stat_accuracy_up.tres")
const ApUp = preload("res://data/status_effects/ap_boost.tres")
const HealingLeaf = preload("res://data/status_effects/healing_leaf.tres")
const SpeedUp = preload("res://data/status_effects/stat_speed_up.tres")
const Cotton = preload("res://data/status_effects/cottoned_on.tres")
const LockedOn = preload("res://data/status_effects/locked_on.tres")
const ContactDmgIce = preload("res://data/status_effects/contactdmg_ice.tres")
const ContactDmgMetal = preload("res://data/status_effects/contactdmg_metal.tres")
const ContactDmgGlitter = preload("res://data/status_effects/contactdmg_glitter.tres")
const ContactDmgPoison = preload("res://data/status_effects/contactdmg_poison.tres")
const ContactDmgAstral = preload("res://data/status_effects/contactdmg_astral.tres")
const ContactDmgWater = preload("res://data/status_effects/contactdmg_water.tres")
const ContactDmgPlastic = preload("res://data/status_effects/contactdmg_plastic.tres")
const ContactDmgAir = preload("res://data/status_effects/contactdmg_air.tres")
const ContactDmgGlass = preload("res://data/status_effects/contactdmg_glass.tres")
const ContactDmgFire = preload("res://data/status_effects/contactdmg_fire.tres")
const ContactDmgLightning = preload("res://data/status_effects/contactdmg_lightning.tres")
const ContactDmgEarth = preload("res://data/status_effects/contactdmg_earth.tres")
const ContactDmgBeast = preload("res://data/status_effects/contactdmg_beast.tres")
const ContactDmgPlant = preload("res://data/status_effects/contactdmg_plant.tres")
const AccDown = preload("res://data/status_effects/stat_accuracy_down.tres")
const Sleep = preload("res://data/status_effects/sleep.tres")
const MatkDown = preload("res://data/status_effects/stat_matk_down.tres")
const Leeched = preload("res://data/status_effects/leeched.tres")
const Burned = preload("res://data/status_effects/burned.tres")
const Berserk_2016 = preload("res://data/status_effects/berserk.tres")
const MdefDown = preload("res://data/status_effects/stat_mdef_down.tres")
const Poisoned = preload("res://data/status_effects/poisoned.tres")
const EvaDown = preload("res://data/status_effects/stat_evasion_down.tres")
const SpeedDown = preload("res://data/status_effects/stat_speed_down.tres")
const RdefDown = preload("res://data/status_effects/stat_rdef_down.tres")
const ApDown = preload("res://data/status_effects/ap_drain.tres")
const RatkDown = preload("res://data/status_effects/stat_ratk_down.tres")
const Shrapnel = preload("res://data/status_effects/shrapnel.tres")
const Conductive = preload("res://data/status_effects/conductive.tres")
const GlassBonds = preload("res://data/status_effects/glass_bonds.tres")
const Resonance = preload("res://data/status_effects/resonance.tres")
const Confused = preload("res://data/status_effects/confused.tres")
const Flinch = preload("res://data/status_effects/flinch.tres")
const Unitarget = preload("res://data/status_effects/unitarget.tres")
const Bomb = preload("res://data/status_effects/bomb.tres")
const Petrified = preload("res://data/status_effects/petrified.tres")
#also fields of fonons, no fun if you don't have that.
const FOF_Dark = preload("res://mods/tales_of_movepack/status_effects/fof_dark.tres")
const FOF_Earth = preload("res://mods/tales_of_movepack/status_effects/fof_earth.tres")
const FOF_Air = preload("res://mods/tales_of_movepack/status_effects/fof_air.tres")
const FOF_Water = preload("res://mods/tales_of_movepack/status_effects/fof_water.tres")
const FOF_Fire = preload("res://mods/tales_of_movepack/status_effects/fof_fire.tres")
const FOF_Light = preload("res://mods/tales_of_movepack/status_effects/fof_light.tres")
const FOF_Dark_Partial = preload("res://mods/tales_of_movepack/status_effects/fof_dark_partial.tres")
const FOF_Earth_Partial = preload("res://mods/tales_of_movepack/status_effects/fof_earth_partial.tres")
const FOF_Air_Partial = preload("res://mods/tales_of_movepack/status_effects/fof_air_partial.tres")
const FOF_Water_Partial = preload("res://mods/tales_of_movepack/status_effects/fof_water_partial.tres")
const FOF_Fire_Partial = preload("res://mods/tales_of_movepack/status_effects/fof_fire_partial.tres")
const FOF_Light_Partial = preload("res://mods/tales_of_movepack/status_effects/fof_light_partial.tres")

var Damage = load("res://data/Damage.gd")
var DamageVfx = load("res://data/attack_vfx/ionised_air.tres")

var STATUS_ARRAY = [Multistrike, MatkUp, EvaUp, Multiattack, RatkUp, RdefUp,
 MindMeld, HealingSteam, ParryStance, AccUp, ApUp, HealingLeaf, SpeedUp,
 Cotton, LockedOn, ContactDmgIce, ContactDmgMetal, ContactDmgGlitter,
 ContactDmgPoison, ContactDmgAstral, ContactDmgWater, ContactDmgPlastic,
 ContactDmgAir, ContactDmgGlass, ContactDmgFire, ContactDmgLightning,
 ContactDmgEarth, ContactDmgBeast, ContactDmgPlant, AccDown, Sleep, MatkDown,
 Leeched, Burned, Berserk_2016, MdefDown, Poisoned, EvaDown, SpeedDown, RdefDown,
 ApDown, RatkDown, Shrapnel, Conductive, GlassBonds, Resonance, Confused,
 Flinch, Unitarget, Bomb, Petrified, FOF_Dark, FOF_Earth, FOF_Air, FOF_Water,
 FOF_Fire, FOF_Light, FOF_Dark_Partial, FOF_Earth_Partial, FOF_Air_Partial,
 FOF_Water_Partial, FOF_Fire_Partial, FOF_Light_Partial]

var toa_mod:ContentInfo = DLC.mods_by_id["tales_of_movepack"]
#this can give you 3 stacks of resonance and kill you.  It's HYPERRESONANCE BABY

#at the end of every move, does a random large effect.

#apply a random status effects with random durations (1-4) (not this one)
#deal damage to random targets (small chance to just kill everyone) (no that's not fun)
#small chance for this damage to be negative *-
var toastMessage = "Fon Collapse!"

#pulled from Treat.gd as we need to do some of these things
#func apply_statuses(user, target, attack_params = {}, toast_message:String = ""):
#	var types = get_types(user)
#	if types.size() > 0:
#		var type = types[0]
#
#
#		var effect = null
#		if i == 0:
#			effect = create_wall_effect(type)
#		elif i == 1:
#			effect = get_contactdmg_effect(type)
#
#		if effect != null:
#			apply_status_effect(target, effect, amount, toast_message)
#			return 
#
#	.apply_statuses(user, target, attack_params, toast_message)

func create_wall_effect(type:ElementalType)->StatusEffect:
	var decoy_path = "res://data/decoys/wall_" + type.id + ".tres"
	if not ResourceLoader.exists(decoy_path):
		return null
	var decoy = load(decoy_path)
	var wall = WallStatus.new()
	wall.set_decoy(decoy)
	return wall


func getTargets(node, args):
	var fighters = node.fighter.battle.get_fighters()
	var targets = node.fighter.battle.rand.rand_int(fighters.size())
	fighters.shuffle()
	return fighters.slice(0, targets)

func applyStatusEffects(node, targets):
	if not targets:
		print("targets was nil!")
		return
	if not node:
		print("node was nil!")
		return
	for target in targets:
		var stacks = node.fighter.battle.rand.rand_int(20)
		if stacks == 20:
			stacks = 4
		elif stacks > 16:
			stacks = 3
		elif stacks > 10:
			stacks = 2
		else:
			stacks = 1
		var effectIndex = node.fighter.battle.rand.rand_int(STATUS_ARRAY.size())
		target.status.add_effect(STATUS_ARRAY[effectIndex], stacks, toastMessage)
	
func dealDamage(node, targets, value):
	print("dealing damage...")
	var damage = Damage.new()
	damage.damage = value
	damage.physicality = 1 #physical
	damage.types = []
	damage.hit_vfx = [ DamageVfx ]
	damage.toast_message = toastMessage
	for target in targets:
		target.get_controller().take_damage(damage)
	pass

func erraticEffect(node, id:String, args):
	var targets = getTargets(node, args)
	var effect = node.fighter.battle.rand.rand_int(20)
	var damage = node.fighter.battle.rand.rand_int(50)
	if effect > 18:
		dealDamage(node, targets, -damage)
	elif effect > 14:
		dealDamage(node, targets, damage)
	else:
		applyStatusEffects(node, targets)
	pass

func erraticEffects(node, id:String, args):
	print("Effects at ", node.get_class())
	var intensity = node.fighter.battle.rand.rand_int(20)
	#a random number of times (1-3), 80% 15% 5%, do the following:
	erraticEffect(node, id, args)
	if intensity > 16:
		erraticEffect(node, id, args)
	if intensity == 20:
		erraticEffect(node, id, args)
	pass

func notify(node, id:String, args):
	if id == "turn_ending":
		erraticEffects(node, id, args)
