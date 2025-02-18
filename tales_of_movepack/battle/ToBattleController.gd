extends Node

signal moves_refreshed
signal turn_action_queue_cleared

const TapeJam = preload("res://data/status_effects/tape_jam.tres")
# PATCH: ADD LINES HERE

const GenericAttack = preload("res://data/battle_move_scripts/GenericAttack.gd")#tales
#todo Func move name to move
const DARK_FOF = "STATUS_FOF_DARK_NAME"
const EARTH_FOF = "STATUS_FOF_EARTH_NAME"
const AIR_FOF = "STATUS_FOF_AIR_NAME"
const WATER_FOF = "STATUS_FOF_WATER_NAME"
const FIRE_FOF = "STATUS_FOF_FIRE_NAME"
const LIGHT_FOF = "STATUS_FOF_LIGHT_NAME"
const FONIC_TAGS = ["poison", "earth", "air", "water", "fire", "artificial_electricity", "sound", "anathema"]
const FONIC_TYPES = ["poison", "earth", "air", "water", "fire", "lightning"]
#Note that monster type must also be added to this, if one of them.

var rand = Random.new()
var FOF_Dark
var FOF_Earth
var FOF_Air
var FOF_Water
var FOF_Fire
var FOF_Light
var Hyperresonance
var fof_change_table = {}

var toa_mod: ContentInfo = DLC.mods_by_id["tales_of_movepack"]

#todo actually only seventh fonists can create hyperresonance
#We don't actually care about what the tags are, just if they're an exact match.
func getFonicId(fighter:FighterNode):
	var monsterForm = fighter.get_general_form()
	var fonicId = 0
	#get all tags matching these, and all types matching the given types.
	#From their positions, construct a binary number unique to those types.
	for i in FONIC_TAGS.size():
		for monster_tag in monsterForm.move_tags:
			if (monster_tag == FONIC_TAGS[i]):
				print(monsterForm.name, " matched fonic tag ", monster_tag)
				fonicId += pow(2, i)
	
	for i in FONIC_TYPES.size():
		for elementalType in monsterForm.elemental_types:
			if (elementalType.id == FONIC_TYPES[i]):
				print(monsterForm.name, " matched fonic type ", elementalType.id)
				fonicId += pow(2, i)
	return fonicId

# PATCH: STOP
var battle:Node
var last_turn_character:WeakRef
var orders:Array
var round_num:int = 0
var started:bool = false

func _ready():
# PATCH: ADD LINES HERE
	FOF_Dark = load("res://mods/tales_of_movepack/status_effects/fof_dark_partial.tres")
	FOF_Earth = load("res://mods/tales_of_movepack/status_effects/fof_earth_partial.tres")
	FOF_Air = load("res://mods/tales_of_movepack/status_effects/fof_air_partial.tres")
	FOF_Water = load("res://mods/tales_of_movepack/status_effects/fof_water_partial.tres")
	FOF_Fire = load("res://mods/tales_of_movepack/status_effects/fof_fire_partial.tres")
	FOF_Light = load("res://mods/tales_of_movepack/status_effects/fof_light_partial.tres")
	Hyperresonance = load("res://mods/tales_of_movepack/status_effects/hyperresonance.tres")
	construct_fof_change_table()
# PATCH: STOP
	battle = get_parent()

func start():
	if Debug.battle_init_pause > 0.0:
		yield (Co.wait(Debug.battle_init_pause), "completed")
	
	yield (run_advantages(), "completed")
	if not battle.is_battle_over():
		battle.join_fighters(false)
		yield (battle.wait_for_animations(), "completed")
		yield (Co.wait(0.5), "completed")
		if Debug.battle_start_pause > 0.0:
			yield (Co.wait(Debug.battle_start_pause), "completed")
		var co = run_battle()
		if co is GDScriptFunctionState:
			yield (co, "completed")
	var winning_team = battle.find_winner_team_id()
	battle.events.notify("battle_ending", {"winning_team":winning_team})
	yield (battle.wait_for_animations(), "completed")
	print("Battle finished. Winner: " + str(winning_team))
	if winning_team == 0 and not started and battle.net_closed_reason == 0:
		SaveState.stats.get_stat("preemptive_wins").report_event()
	battle.end(winning_team)

func refresh_moves():
	var fighters = battle.get_fighters()
	
	for fighter in fighters:
		if not fighter.status.stats_calculated:
			
			
			
			
			
			
			
			
			fighter.status.refresh_stats()
	
	for fighter in fighters:
		fighter.status.reset_moves()
	for fighter in fighters:
		fighter.status.append_shared_ally_moves()
	
	for fighter in fighters:
		fighter.status.refresh_stats()
	
	emit_signal("moves_refreshed")

# PATCH: ADD FUNC
func fofNotify(id:String, args):
	if id == "attack_contact_ending" and args.target != null and args.target != args.fighter and (getFonicId(args.fighter) == getFonicId(args.target)):
		#apply hyperresonance to both target and fighter
		var hyperMessage = "Isofons React!"
		args.fighter.status.add_effect(Hyperresonance, 2, hyperMessage)
		args.target.status.add_effect(Hyperresonance, 2, hyperMessage)
# PATCH: STOP

func notify(id:String, _args):
# PATCH: ADD LINES HERE
	if (toa_mod.to_enable_fof_interactions):
		fofNotify(id, _args)
# PATCH: STOP
	if id == "joined_battle":
		refresh_moves()
	elif id == "fuse_ending":
		refresh_moves()
	elif id == "unfuse_ending":
		refresh_moves()

func run_battle():
	while not battle.is_battle_over():
		battle.tutorials_this_round.clear()
		
		battle.join_fighters(true)
		yield (battle.wait_for_animations(), "completed")
		battle.events.notify("round_starting", {"round_num":round_num})
		yield (flush_turn_action_queue(), "completed")
		
		
		
		if battle.is_battle_over():
			break
		
		for fighter in battle.get_fighters():
			
			
			fighter.damage_this_round = 0
			fighter.next_tape = null
			fighter.next_items.clear()
			fighter.will_fuse = false
			fighter.just_desynced = false
		
		var sync_co = do_sync_check()
		if sync_co is GDScriptFunctionState:
			yield (sync_co, "completed")
		
		battle.events.order_phase = true
		while _is_any_untransformed():
			var co = transform_humans()
			if co is GDScriptFunctionState:
				yield (co, "completed")
		
		if battle.is_battle_over():
			break
		
		battle.camera_clear_state()
		
		started = true
		
		if battle.get_active_teams().size() >= 2:
			
			
			
			var co = request_orders()
			if co is GDScriptFunctionState:
				co = yield (co, "completed")
			battle.events.order_phase = false
			
			if battle.is_battle_over():
				break
			
			if not battle.events.notify("execution_starting", {"orders":orders}):
				co = execute_orders(orders)
				if co is GDScriptFunctionState:
					yield (co, "completed")
				battle.events.notify("execution_ending", {"orders":orders})
				yield (flush_turn_action_queue(), "completed")
				if battle.find_winner_team_id() != null:
					break
		
		battle.events.notify("round_ending")
		yield (flush_turn_action_queue(), "completed")
		battle.process_free_list()
		
		round_num += 1

func _is_any_untransformed()->bool:
	for fighter in battle.get_fighters(false):
		if not fighter.is_transformed():
			return true
	return false

func transform_humans():
	
	
	
	var request = battle.get_net_request()
	if request:
		request.start_next_tape()
	
	var transforms: = []
	
	
	for fighter in battle.get_fighters(false):
		if not fighter.is_transformed() and not fighter.is_player_controlled() and not fighter.is_remote_player_controlled():
			var transform = _transform_human(fighter)
			if transform is GDScriptFunctionState:
				transform = yield (transform, "completed")
			transforms.push_back(transform)
	
	
	yield (battle.wait_for_animations(), "completed")
	
	
	for fighter in battle.get_fighters(false):
		if not fighter.is_transformed() and fighter.is_player_controlled():
			var transform = _transform_human(fighter)
			if transform is GDScriptFunctionState:
				transform = yield (transform, "completed")
			transforms.push_back(transform)

	if request:
		var co = request.wait_for_next_tapes()
		if co is GDScriptFunctionState:
			yield (co, "completed")
	
	
	for fighter in battle.get_fighters(false):
		if not fighter.is_transformed() and fighter.is_remote_player_controlled():
			var transform = _transform_human(fighter)
			if transform is GDScriptFunctionState:
				transform = yield (transform, "completed")
			transforms.push_back(transform)

	
	
	transforms.sort_custom(self, "_cmp_transform")
	
	
	for transform in transforms:
		battle.rand.push_seed(transform.seed_value)
		battle.camera_set_state("request_use_next_tape", [transform.fighter.slot])
		transform.transform.call_func()
		
		transform.turn_action_queue = battle.turn_action_queue.duplicate()
		battle.turn_action_queue.clear()
		transform.seed_value = battle.rand.seed_value
		battle.rand.pop()
		
	assert (battle.turn_action_queue.size() == 0)
	yield (flush_turn_action_queue(), "completed")
	
	
	for transform in transforms:
		battle.rand.push_seed(transform.seed_value)
		battle.turn_action_queue.append_array(transform.turn_action_queue)
		yield (flush_turn_action_queue(), "completed")
		battle.rand.pop()

func _cmp_transform(a, b)->bool:
	if a.priority > b.priority:
		return true
	if a.priority == b.priority:
		
		return a.fighter.get_index() < b.fighter.get_index()
	assert (a.priority < b.priority)
	return false

func _transform_human(fighter):
	assert ( not fighter.is_transformed())
	
	battle.rand.push(fighter.get_net_player_id())
	
	var tape_jam = fighter.status.get_effect_node(TapeJam)
	assert ( not tape_jam)
	if tape_jam:
		
		tape_jam.remove()
	
	var transform = fighter.get_controller().request_use_next_tape()
	if transform is GDScriptFunctionState:
		transform = yield (transform, "completed")
	assert (transform is Bind)
	var seed_value = battle.rand.seed_value
	var priority = fighter.status.speed * 100 + battle.rand.rand_int(100)
	
	battle.rand.pop()
	
	return {
		priority = priority, 
		seed_value = seed_value, 
		fighter = fighter, 
		transform = transform, 
	}

func do_sync_check():
	var net_request = battle.get_net_request()
	if net_request and not net_request.closed:
		
		var states = [battle.rand.seed_value]
		for f in battle.get_fighters(true):
			states.push_back(f.status.get_hashable_state())
		print(states)
		net_request.send_state_hash(states.hash())
		
		var co = net_request.check_state_hash()
		if co is GDScriptFunctionState:
			yield (co, "completed")

func request_orders():
	
	
	
	orders.clear()
	var fighters = battle.get_fighters(false)
	battle.opposing_team_preview.enable()
	
	var any_ui_fighters = false
	for fighter in fighters:
		if fighter.get_controller().uses_order_menu():
			any_ui_fighters = true
	
	var ui_orders = {}
	if any_ui_fighters:
		ui_orders = yield (request_ui_orders(), "completed")
	
	for fighter_orders in ui_orders.values():
		for order in fighter_orders:
			if order.type == BattleOrder.OrderType.FLEE:
				battle.fleeing_team = order.fighter.team
				return 
	
	
	
	fighters = battle.get_fighters(false)
	
	
	
	for fighter in fighters:
		if fighter.get_controller().uses_order_menu():
			if ui_orders.has(fighter):
				orders += ui_orders[fighter]
				for order in ui_orders[fighter]:
					print(order)
		elif fighter.get_controller() is RemotePlayerFighterController and not battle.events.notify("request_orders", {fighter = fighter}):
			var fighter_orders = fighter.get_controller().request_orders()
			if fighter_orders is GDScriptFunctionState:
				fighter_orders = yield (fighter_orders, "completed")
			assert (fighter_orders is Array)
			
			for order in fighter_orders:
				print(order)
				if order.type == BattleOrder.OrderType.FLEE:
					battle.fleeing_team = order.fighter.team
					return 
				
				orders.push_back(order)
			yield (Co.next_frame(), "completed")
	
	
	
	var i: = 0
	while i < orders.size():
		var order:BattleOrder = orders[i]
		
		if order.type == BattleOrder.OrderType.ITEM and order.order and order.order.item.battle_usage == BaseItem.BattleUsage.FREE_USE:
			if not order.argument or not order.argument.get("already_used"):
				assert (order.fighter.get_controller() is RemotePlayerFighterController)
				order.order.use(BaseItem.ContextKind.CONTEXT_BATTLE, order.fighter, order.argument)
			
			orders.remove(i)
			continue
				
		i += 1
	
	
	for fighter in fighters:
		if fighter.get_controller().uses_order_menu() or fighter.get_controller() is RemotePlayerFighterController:
			continue
		
		if not battle.events.notify("request_orders", {fighter = fighter}):
			var fighter_orders = fighter.get_controller().request_orders()
			if fighter_orders is GDScriptFunctionState:
				fighter_orders = yield (fighter_orders, "completed")
			assert (fighter_orders is Array)
			
			for order in fighter_orders:
				print(order)
				orders.push_back(order)
			yield (Co.next_frame(), "completed")
	
	battle.opposing_team_preview.disable()

func request_ui_orders():
	var order_menu = preload("res://battle/ui/OrderMenu.tscn").instance()
	order_menu.battle = battle

	battle.canvas_layer.add_child(order_menu)
	var ui_orders = yield (order_menu, "all_orders_chosen")
	battle.canvas_layer.remove_child(order_menu)
	order_menu.queue_free()
	
	var result = {}
	for order in ui_orders:
		assert (order.fighter)
		
		
		if order.type == BattleOrder.OrderType.ITEM and order.argument and order.argument.get("already_used"):
			continue
		
		if not result.has(order.fighter):
			result[order.fighter] = []
		result[order.fighter].push_back(order)
	
	return result

func run_advantages():
	var team = battle.get_teams(false, false)[0]
	var player_controlled = false
	for f in team:
		if f.get_controller() is PlayerFighterController:
			player_controlled = true
			break
	if not player_controlled or battle.advantages.size() == 0:
		return Co.pass()
	
	for advantage in battle.advantages:
		if advantage == "fire":
			run_advantage_fire(team[0])
		elif advantage == "plant":
			run_advantage_plant(team)
		elif advantage == "lightning":
			run_advantage_lightning(team)
		
		yield (flush_turn_action_queue(), "completed")

func run_advantage_fire(fighter):
	var attack_types = [preload("res://data/elemental_types/fire.tres")]
	var hit_vfx = [preload("res://data/hit_vfx/hit.tres")]
	for target in battle.get_fighters(false):
		if target.team == fighter.team:
			continue
		
		if not target.status_bubble:
			target.add_status_bubble(target.slot, target.status.get_snapshot())
		
		var damage = Damage.new()
		damage.source = fighter
		damage.damage = BattleFormulas.get_damage(battle.rand, 30, fighter.status.level, fighter.status.melee_attack, target.status.melee_defense, attack_types, target.status.get_types())
		damage.types = attack_types
		damage.hit_vfx = hit_vfx
		target.get_controller().take_damage_with_chemistry(damage)

func run_advantage_plant(fighters):
	for f in fighters:
		var status = WallStatus.new()
		status.set_decoy(preload("res://data/decoys/wall_plant.tres"))
		var status_node = StatusEffectNode.new()
		status_node.effect = status
		status_node.amount = 2
		f.status.add_effect_quietly(status_node)
		f.status.update_decoy()

func run_advantage_lightning(fighters):
	for f in fighters:
		f.status.ap += 1

func flush_turn_action_queue():
	kill_dead_fighters()
	var i = 0
	while i < battle.turn_action_queue.size():
		var action = battle.turn_action_queue[i]
		if action is BattleOrder:
			execute_order(action)
		elif action is Bind:
			action.call_func()
		elif action is FuncRef:
			action.call_func()
		else :
			push_error("Unable to execute turn action " + str(action))
		kill_dead_fighters()
		i += 1
	battle.turn_action_queue.clear()
	emit_signal("turn_action_queue_cleared")
	
	yield (battle.wait_for_animations(), "completed")
	remove_dead_fighters()
	yield (battle.hide_message(), "completed")

func erase_fighter_turn_actions(fighter:Node):
	for i in range(battle.turn_action_queue.size() - 1, - 1, - 1):
		var action = battle.turn_action_queue[i]
		if action is BattleOrder and action.fighter == fighter:
			battle.turn_action_queue.remove(i)

func execute_orders(orders:Array, sync_animations:bool = true):
	sort_orders(orders)
	
	for fighter in battle.get_fighters():
		fighter.had_turn = false
	
	for order in orders:
		if order.fighter.status.dead:
			continue
		
		if not order.consumes_turn() or not battle.events.notify("turn_starting", {
			"fighter":order.fighter, 
			"order":order
		}):
			battle.queue_turn_action(order)
			order.fighter.had_turn = true
			
			yield (flush_turn_action_queue(), "completed")
			
			if order.consumes_turn():
				battle.events.notify("turn_ending", {
					"fighter":order.fighter, 
					"order":order
				})
			yield (flush_turn_action_queue(), "completed")
			order.fighter.turn_num += 1
		
		battle.queue_hide_message()
		if sync_animations:
			yield (battle.wait_for_animations(), "completed")
		
		if battle.is_battle_over():
			break

func sort_orders(orders:Array):
	
	for order in orders:
		order.refresh_priority(battle.rand)
	orders.sort_custom(self, "_sort_order_pair")

func _sort_order_pair(a:BattleOrder, b:BattleOrder):
	if a.type < b.type:
		return true
	if a.type > b.type:
		return false
	if a.priority > b.priority:
		return true
	if a.priority < b.priority:
		return false
	if a.type == BattleOrder.OrderType.FIGHT and b.type == BattleOrder.OrderType.FIGHT:
		if a.speed > b.speed:
			return true
		if a.speed < b.speed:
			return false
		return a.tie_break > b.tie_break
	return false

func execute_order(order:BattleOrder):
	if order.fighter.status.dead or order.fighter.just_desynced:
		return 
	if order.is_callback():
		order.order.call_func()
	else :
		print("Executing order: ", order)
		print("Seed: ", battle.rand.seed_value)
		match order.type:
			BattleOrder.OrderType.NOOP:
				pass
			BattleOrder.OrderType.SWITCH:
				execute_switch(order)
			BattleOrder.OrderType.ITEM:
				execute_item(order)
			BattleOrder.OrderType.FUSE:
				execute_fuse(order)
			BattleOrder.OrderType.FIGHT:
				execute_move(order)
			_:
				push_error("Unknown order type: " + str(order.type))
		last_turn_character = weakref(order.character)
		order.notify_executed()

func execute_fuse(order:BattleOrder):
	if order.argument and order.argument.get("already_done"):
		return 
	if not order.argument:
		order.argument = {}
	order.argument.already_done = true
	
	if order.fighter.is_fusion():
		_execute_unfuse(order)
		return 
	
	var fuser = null
	if order.argument and order.argument.has("fuser"):
		fuser = order.argument.fuser
	else :
		fuser = order.fighter.get_fuser()
	if fuser == null:
		return 
	
	
	
	
	battle.rand.push(order.fighter.get_net_player_id())
	
	var team = [order.fighter, fuser]
	
	battle.events.notify("before_fuse_starting", {"fighters":team})
	var name0 = team[0].get_name_with_team()
	var name1 = team[1].get_general_name() if team[1] is FighterNode else team[1].character.name
	
	battle.queue_camera_set_state("fusion", [team[0].slot, team[1].slot] if team[1] is FighterNode else [team[0].slot])
	
	
	var is_fusing = not battle.events.notify("fuse_starting", {"fighters":team})
	if is_fusing:
		
		if not (fuser is FighterNode):
			var vfx: = [OutOfBattleFuseVfx.new()]
			vfx[0].character = fuser.character
			battle.queue_animation(Bind.new(order.fighter, "animate_vfx_sequence", [vfx]))
			
		battle.queue_message(Loc.trf("BATTLE_FUSING", [name0, name1]), true)
		
		if fuser is FighterNode:
			_normal_fuse(order.fighter, fuser)
		else :
			_out_of_battle_fuse(order.fighter, fuser.character, fuser.tape)
		
		battle.events.notify("fuse_ending", {"fighter":order.fighter})
		battle.queue_animation(Bind.new(self, "_after_fusion", [order.fighter, order.fighter.get_species()]))
	
	battle.queue_hide_message()
	
	if is_fusing:
		if team[0].get_controller().has_node("BattleFusion"):
			battle.queue_animation(Bind.new(team[0].get_controller().get_node("BattleFusion"), "run"))
	
	battle.rand.pop()

func _normal_fuse(fighter:FighterNode, fuser:FighterNode)->void :
	fighter.set_decoy(null)
	fuser.set_decoy(null)
	
	for c in fuser.get_characters():
		fuser.remove_child(c)
		fighter.add_child(c)
		
		if fighter.team == 0 and c.character.partner_id != "":
			SaveState.set_flag("fused_with_" + c.character.partner_id, true)
			SaveState.stats.get_stat("fused_with").report_event(c.character.partner_id)
	
	fighter.status.refresh_stats()
	
	for effect in fuser.status.get_effects():
		fuser.status.remove_child(effect)
		fighter.status.add_effect_quietly(effect)
	fighter.status.refresh_stats()
	fighter.status.ap += fuser.status.ap
	battle.remove_child(fuser)
	
	var vacant_slot = fuser.slot
	battle.queue_animation(Bind.new(self, "_animate_fusion", [[fighter, fuser], fighter.generate_transform_animation(), vacant_slot, fighter.slot]))
	fighter.status.update_decoy()

func _out_of_battle_fuse(fighter:FighterNode, fuser_char:Character, fuser_tape:MonsterTape)->void :
	assert (fuser_char)
	assert (fuser_tape)
	
	var char_node = CharacterNode.new()
	char_node.character = fuser_char
	char_node.active_tape = fuser_tape
	char_node.temporary_fusion_part = true
	fighter.add_child(char_node)
	
	if fuser_char.partner_id != "" and fighter.team == 0 and fighter.get_controller().is_player():
		SaveState.set_flag("fused_with_" + fuser_char.partner_id, true)
		SaveState.stats.get_stat("fused_with").report_event(fuser_char.partner_id)
	
	fighter.status.refresh_stats()
	
	battle.queue_animation(Bind.new(self, "_animate_out_of_battle_fusion", [fighter, fuser_char, fighter.generate_transform_animation()]))

func _after_fusion(fighter:FighterNode, species:Array):
	if fighter.team == 0 and fighter.get_controller().is_player():
		SaveState.stats.get_stat("fusions_formed").report_event(species)
	else :
		SaveState.stats.get_stat("fusions_encountered").report_event(species)

func _animate_fusion(team, transform_anim:Bind, vacant_slot, fusion_slot):
	team[1].status_bubble.fade_out_and_free()
	team[1].status_bubble = null
	
	if battle.battle_music_vox and UserSettings.audio_vocals:
		battle.music.crossfade(battle.battle_music_vox)
	
	yield (Co.join([
		vacant_slot.move_to(team[0].slot.global_transform.origin), 
		transform_anim.call_func(), 
		vacant_slot.transform_to(null, [], false), 
		Co.delayed(1.3, Bind.new(self, "_animate_fusion_zoom", [team, fusion_slot]))
	]), "completed")
	team[1].animate_leave_slot(vacant_slot)
	vacant_slot.reset_position()
	team[1].queue_free()
	
	battle.fusion_label_banner.show_banner(team[0].get_form_name())
	
	fusion_slot.play_animation("monster_battle_cry")
	yield (Co.safe_wait(self, 1.0), "completed")
	yield (battle.fusion_label_banner.hide_banner(), "completed")
	
	MusicSystem.mute = false

func _animate_out_of_battle_fusion(fighter, fuser_char, fighter_transform:Bind):
	if battle.battle_music_vox and UserSettings.audio_vocals:
		battle.music.crossfade(battle.battle_music_vox)
	
	var vfx: = [OutOfBattleFuseVfx.new()]
	vfx[0].character = fuser_char
	vfx[0].part = 1
	var co_list: = [fighter.animate_vfx_sequence(vfx), fighter_transform.call_func()]
	return Co.join(co_list)

func _animate_fusion_zoom(_team, fusion_slot):
	battle.camera_set_state("fusion_zoom", [fusion_slot], 0.2)
	yield (Co.wait(0.2), "completed")
	battle.shock_overlay.play()

func _execute_unfuse(order:BattleOrder):
	var fighter = order.fighter
	unfuse(fighter)
	battle.queue_hide_message()

func unfuse(fighter, message:String = "")->bool:
	assert (fighter.is_fusion())
	battle.camera_set_state("execute_unfuse", [fighter.slot])
	
	
	
	
	battle.rand.push(fighter.get_net_player_id())
	
	var result = false
	if not battle.events.notify("unfuse_starting", {"fighter":fighter}):
		
		
		
		erase_fighter_turn_actions(fighter)
		
		var heal_after_unfuse = not Character.is_human(fighter.get_character_kind())
		
		var char2 = fighter.get_characters()[1]
		var new_fighter = null
		if not char2.temporary_fusion_part:
			fighter.set_decoy(null)
			new_fighter = FighterNode.new()
			new_fighter.team = fighter.team
		
		fighter.remove_child(char2)
		if new_fighter:
			new_fighter.add_child(char2)
			battle.add_child_below_node(fighter, new_fighter)
			
			new_fighter.set_preferred_slot()
			assert (new_fighter.slot != null)
			if new_fighter.slot.get_index() < fighter.slot.get_index():
				
				
				
				battle.move_child(new_fighter, fighter.get_index())
		else :
			battle.queue_node_free(char2)
		
		fighter.status.refresh_stats()
		
		if new_fighter:
			new_fighter.status.refresh_stats()
			
			
			var total_ap = fighter.status.ap
			var half_ap = int(total_ap / 2)
			fighter.status.ap = half_ap
			new_fighter.status.ap = half_ap
			if 2 * half_ap < total_ap:
				(fighter if battle.rand.rand_bool() else new_fighter).status.ap += total_ap - 2 * half_ap
			
			new_fighter.add_child(fighter.get_controller().unfuse())
			
			
			for effect in fighter.status.get_effects():
				effect.unfuse(new_fighter)
		
		if heal_after_unfuse:
			fighter.status.hp = fighter.status.max_hp
			if new_fighter:
				new_fighter.status.hp = new_fighter.status.max_hp
		
		if new_fighter:
			new_fighter.get_controller().join_battle(false)
		
		if message != "" and new_fighter:
			var name0 = fighter.get_name_with_team()
			var name1 = new_fighter.get_name_with_disambiguator()
			battle.queue_message(Loc.trf(message, [name0, name1]))
		
		if new_fighter:
			var snap1 = fighter.status.get_snapshot()
			var snap2 = new_fighter.status.get_snapshot()
			var transform_anim = fighter.generate_transform_animation()
			var transform2_anim = new_fighter.generate_transform_animation()
			var enter_slot_anim = new_fighter.generate_enter_slot_animation()
			battle.queue_animation(Bind.new(self, "_animate_unfusion", [fighter, new_fighter, snap1, snap2, new_fighter.slot, transform_anim, transform2_anim, enter_slot_anim]))
			fighter.status.update_decoy()
			new_fighter.status.update_decoy()
		else :
			battle.queue_animation(Bind.new(self, "_animate_out_of_battle_unfusion", [fighter, char2.character, fighter.generate_transform_animation()]))
		
		if heal_after_unfuse:
			var flinch = preload("res://data/status_effects/flinch.tres") as StatusEffect
			if not fighter.status.has_tag("flinch"):
				fighter.status.add_effect(flinch, 1)
			if new_fighter and not new_fighter.status.has_tag("flinch"):
				new_fighter.status.add_effect(flinch, 1)
		
		battle.events.notify("unfuse_ending", {"fighters":[fighter, new_fighter]})
		
		result = true
	
	battle.rand.pop()
	return result

func _animate_out_of_battle_unfusion(fighter, fuser_char:Character, fighter_animation:Bind):
	if battle.battle_music and not _find_human_fusion():
		battle.music.crossfade(battle.battle_music)
	
	var vfx: = [OutOfBattleFuseVfx.new()]
	vfx[0].character = fuser_char
	vfx[0].unfuse = true
	fighter.animate_vfx_sequence(vfx)
	return fighter_animation.call_func()

func _find_human_fusion():
	for f in battle.get_fighters():
		if not f.is_fusion():
			continue
		for c in f.get_characters():
			if Character.is_human(c.character.character_kind):
				return f
	return null

func _animate_unfusion(fighter1, fighter2, snap1, snap2, slot2, transform_anim:Bind, transform2_anim:Bind, enter_slot_anim:Bind):
	
	if battle.battle_music and not _find_human_fusion():
		battle.music.crossfade(battle.battle_music)
	
	transform_anim.call_func()
	yield (Co.wait(1.0), "completed")
	transform2_anim.call_func()
	enter_slot_anim.call_func()
	slot2.move_to(fighter1.slot.global_transform.origin, true)
	yield (slot2.reset_position(), "completed")
	if fighter2.get_controller().status_bubble_enabled:
		fighter2.add_status_bubble(slot2, snap2)
	if fighter1.status_bubble:
		fighter1.status_bubble.set_snapshot(snap1, true)
	if fighter2.status_bubble:
		fighter2.status_bubble.set_snapshot(snap2, false)
		yield (fighter2.status_bubble.fade_in(), "completed")

# PATCH: ADD FUNC
func dict_append(dict, key, value):
	var new_dict = {key: value}
	dict.merge(new_dict)
# PATCH: STOP

#Move of form MOVE_SMACK_NAME
# PATCH: ADD FUNC
func add_fof_change(trigger_move_name:String, earthChange:String = "", airChange:String = "", waterChange:String = "", fireChange:String = ""):
	var fof_changes = {}
	if earthChange != "":
		dict_append(fof_changes, EARTH_FOF, earthChange)
	if airChange != "":
		dict_append(fof_changes, AIR_FOF, airChange)
	if waterChange != "":
		dict_append(fof_changes, WATER_FOF, waterChange)
	if fireChange != "":
		dict_append(fof_changes, FIRE_FOF, fireChange)
	dict_append(fof_change_table, trigger_move_name, fof_changes)
# PATCH: STOP
#todo I'm going to want console commands for adding my statuses

#Super inefficient but I'd have to build a map or something.
#I probably should.
# PATCH: ADD FUNC
func get_move_by_name(move_name:String):
	for move in BattleMoves.all_valid:
		if (move.name == move_name):
			return deep_copy(move)
	print("Failed to get move ", move_name, "!")
# PATCH: STOP

#I don't think I want smack/spit to end up with these, but it helps for testing.
#todo check if move is in table, else apply rules list for FOF changes.
#do a thing where I shift the move up one in cost.
#build an array of every move (non-wall) type by cost.
# for any moves, use type of fighter
# PATCH: ADD FUNC
func construct_fof_change_table():
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
# PATCH: STOP

# PATCH: ADD FUNC
func disambiguate_fof_change(current_move:BattleMove, first_effect_name:String, second_effect_name:String):
	print("Picking between ", first_effect_name, " and ", second_effect_name)
	var first = rand.rand_bool()
	var first_val = lookup_fof_change(current_move, (first_effect_name if first else second_effect_name))
	if (first_val != null):
		return first_val
	#otherwise return the other one
	return lookup_fof_change(current_move, (second_effect_name if first else first_effect_name))
# PATCH: STOP

# PATCH: ADD FUNC
func lookup_fof_change(current_move:BattleMove, effect_name:String):
	print("lookup fof change ", effect_name)
	var fof_change = fof_change_table.get(current_move.name)
	if fof_change == null:
		print("no move entry for ", current_move.name)
		return null
	
	#light and dark count as two other fields, but have no fof changes of their own.
	if effect_name == DARK_FOF:
		return disambiguate_fof_change(current_move, EARTH_FOF, WATER_FOF)
	if effect_name == LIGHT_FOF:
		return disambiguate_fof_change(current_move, AIR_FOF, FIRE_FOF)
	var new_move_name = fof_change.get(effect_name)
	if new_move_name == null:
		print("no effect entry for ", effect_name, " in ", current_move.name)
		return null
	print("fof change to ", new_move_name)
	return get_move_by_name(new_move_name)
# PATCH: STOP

# PATCH: ADD FUNC
func get_fof_color(fof_name):
	match fof_name:
		DARK_FOF:
			return Color.purple
		EARTH_FOF:
			return Color.saddlebrown
		AIR_FOF:
			return Color.aquamarine
		WATER_FOF:
			return Color.dodgerblue
		FIRE_FOF:
			return Color.coral
		LIGHT_FOF:
			return Color.yellow
# PATCH: STOP

# PATCH: ADD FUNC
func fof_change_check(current_move:BattleMove, fighter:FighterNode):
	print(current_move.name)
	for effect_node in fighter.status.get_effects():
		var effect = effect_node.effect
		var effect_name = effect.get_name()
		print(effect_name)
		var new_move = lookup_fof_change(current_move, effect_name)
		print("fof change? ", current_move)
		if new_move != null:
			print("fof change! ", new_move.name)
			#give cheaper cost so move doesn't fail
			if (current_move.cost < new_move.cost):
				new_move.cost = current_move.cost
			fighter.status.remove_child(effect_node)
			fighter.battle.queue_node_free(effect_node)
			var toast = battle.create_toast()
			#todo color based on field used
			toast.setup_text(str("FOF Change: ", tr(new_move.name), "!"), get_fof_color(effect_name))
			battle.queue_play_toast(toast, fighter.slot)
			return new_move
	return current_move#neguc: No Ethical Gamification Under Capitalism
# PATCH: STOP

# PATCH: ADD FUNC
func add_fonic_effect(move:GenericAttack, effect:StatusEffect):
	#FoF can only be applied at the same time as other statuses.
	#Don't try to apply to things that pick at random.
	print("adding ", effect.get_name())
	if (move.status_effects_to_apply == 0):
		#Don't mess with existing percentages
		if (move.status_effect_chance == 0):
			if (move.cost == 0):
				move.status_effect_chance = 100#todo 25
			elif (move.cost == 1):
				move.status_effect_chance = 50
			else:
				move.status_effect_chance = 100
		move.target_status_effects.append(effect)
	print("6", move.name)
	return move
# PATCH: STOP

# PATCH: ADD FUNC
func add_residual_fonic_effects(move:BattleMove, fighter:FighterNode):
	#hmm will this leak resources?
	move = deep_copy(move)
	print("4", move.name)
	if move is GenericAttack:
		#need to make all this a function
		if (false):
			return
		for tag in move.tags:
				match tag:
					"poison":
						move = add_fonic_effect(move, FOF_Dark)
					"earth":
						move = add_fonic_effect(move, FOF_Earth)
					"air":#send film to bosuman hey I happened to be wearing your shirt while we made this
						move = add_fonic_effect(move, FOF_Air)
					"water":
						move = add_fonic_effect(move, FOF_Water)
					"fire":
						move = add_fonic_effect(move, FOF_Fire)
					"lightning":
						move = add_fonic_effect(move, FOF_Light)
					"any":
						for type in fighter.status.types:
							match type.name:
								"ELEMENTAL_TYPE_POISON":
									move = add_fonic_effect(move, FOF_Dark)
								"ELEMENTAL_TYPE_EARTH":
									move = add_fonic_effect(move, FOF_Earth)
								"ELEMENTAL_TYPE_AIR":#send film to bosuman hey I happened to be wearing your shirt while we made this
									move = add_fonic_effect(move, FOF_Air)
								"ELEMENTAL_TYPE_WATER":
									move = add_fonic_effect(move, FOF_Water)
								"ELEMENTAL_TYPE_FIRE":
									move = add_fonic_effect(move, FOF_Fire)
								"ELEMENTAL_TYPE_LIGHTNING":
									move = add_fonic_effect(move, FOF_Light)
							print("matched any! ", type.name)
				#each time you use a move with the sound tag it ticks up a hidden counter and when it gets to seven it makes a hyperresonance which does *things*
	return move
# PATCH: STOP

#battle order stuff is a reason to do this on move execute instead
#that way a FOF is used ASAP, which feels better.

#I should put a [modutils] toggle in settings for all this fon nonsense.
#The moves don't need it.

#need a method which deep copies a move
#need one for battlemove and purestatus too, maybe others.
#or I could try to load it from its path.
# PATCH: ADD FUNC
func deep_copy(move):
	print(move.resource_path)
	print(move.get_path())
	print(move.get_name())
	#print("8", move.filename)
	print(move.is_local_to_scene())
	#return load(move.resource_path
	return move.duplicate()
# PATCH: STOP

func execute_move(order:BattleOrder):
	var user = order.fighter
	var move:BattleMove = order.order
	var arg = order.argument
# PATCH: ADD LINES HERE
	print("toa fof enabled: ", toa_mod.to_enable_fof_interactions)
	if (toa_mod.to_enable_fof_interactions):
		move = fof_change_check(move, user)
		move = add_residual_fonic_effects(move, user)
# PATCH: STOP
	battle.queue_camera_set_state("execute_move", [user.slot])
	user.get_controller().use_move_turn(move, arg)

func execute_switch(order:BattleOrder):
	var user = order.fighter
	var tape:MonsterTape = order.order
	battle.queue_camera_set_state("execute_switch", [user.slot])
	user.get_controller().switch_tape(tape)

func execute_item(order:BattleOrder):
	var user = order.fighter
	var item = order.order
	var arg = order.argument
	if is_instance_valid(item):
		battle.queue_animate_turn_start(user, item.get_item_name())
		battle.queue_camera_set_state("execute_item", [user.slot])
		user.get_controller().use_item(item, arg)
		battle.queue_animate_turn_end()
		battle.queue_hide_message()

func kill_dead_fighters():
	for _i in range(2):
		
		
		for f in battle.get_fighters():
			var hp = f.status.hp if f.is_transformed() else f.status.backing_hp
			var out_of_tapes = ( not f.is_transformed() or f.status.hp <= 0) and f.get_controller().get_available_tapes().size() == 0
			if not f.status.dead and (hp <= 0 or out_of_tapes):
				f.get_controller().die()
	
	battle.queue_hide_message()

func remove_dead_fighters():
	for f in battle.get_fighters():
		if f.status.dead:
			if f.status_bubble:
				f.status_bubble.queue_free()
			f.status_bubble = null
			if f.get_controller().is_removed_on_defeat():
				battle.remove_child(f)
				battle.queue_node_free(f)
	battle.background.check_wide_mode()
