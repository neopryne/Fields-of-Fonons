extends Node

signal moves_refreshed
signal turn_action_queue_cleared

const TapeJam = preload("res://data/status_effects/tape_jam.tres")

var battle:Node
var last_turn_character:WeakRef
var orders:Array
var round_num:int = 0
var started:bool = false

func _ready():
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

func notify(id:String, _args):
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
			fighter.next_item = null
			fighter.will_fuse = false
			fighter.just_desynced = false
		
		do_sync_check()
		
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
	
	
	for fighter in battle.get_fighters(false):
		if not fighter.is_transformed() and not fighter.is_player_controlled() and not fighter.is_remote_player_controlled():
			var co = _transform_human(fighter)
			if co is GDScriptFunctionState:yield (co, "completed")
			if battle.is_battle_over():return 
	
	
	for fighter in battle.get_fighters(false):
		if not fighter.is_transformed() and fighter.is_player_controlled():
			var co = _transform_human(fighter)
			if co is GDScriptFunctionState:yield (co, "completed")
			if battle.is_battle_over():return 
	
	if request:
		var co = request.wait_for_next_tapes()
		if co is GDScriptFunctionState:
			yield (co, "completed")
	
	
	for fighter in battle.get_fighters(false):
		if not fighter.is_transformed() and fighter.is_remote_player_controlled():
			var co = _transform_human(fighter)
			if co is GDScriptFunctionState:yield (co, "completed")
			if battle.is_battle_over():return 

func _transform_human(fighter):
	assert ( not fighter.is_transformed())
	
	battle.rand.push(fighter.get_net_player_id())
	
	var tape_jam = fighter.status.get_effect_node(TapeJam)
	assert ( not tape_jam)
	if tape_jam:
		tape_jam.remove()
	
	battle.camera_set_state("request_use_next_tape", [fighter.slot])
	var co = fighter.get_controller().request_use_next_tape()
	if co is GDScriptFunctionState:
		yield (co, "completed")
	yield (flush_turn_action_queue(), "completed")
	
	battle.rand.pop()

func do_sync_check():
	var net_request = battle.get_net_request()
	if net_request and not net_request.closed:
		
		var states = [battle.rand.seed_value]
		for f in battle.get_fighters(true):
			states.push_back(f.status.get_hashable_state())
		print(states)
		net_request.send_state_hash(states.hash())
		
		net_request.check_state_hash()

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
		elif not battle.events.notify("request_orders", {fighter = fighter}):
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
		return a.speed > b.speed
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
	if order.argument and order.argument.already_done:
		return 
	if not order.argument:
		order.argument = {}
	order.argument.already_done = true
	
	if order.fighter.is_fusion():
		_execute_unfuse(order)
		return 
	var fuser = order.fighter.get_fuser()
	if fuser == null:
		return 
	
	
	
	
	battle.rand.push(order.fighter.get_net_player_id())
	
	var team = [order.fighter, fuser]
	
	battle.events.notify("before_fuse_starting", {"fighters":team})
	var name0 = team[0].get_name_with_team()
	var name1 = team[1].get_general_name()
	
	battle.queue_camera_set_state("fusion", [team[0].slot, team[1].slot])
	
	battle.queue_message(Loc.trf("BATTLE_FUSING", [name0, name1]), true)
	
	var is_fusing = not battle.events.notify("fuse_starting", {"fighters":team})
	if is_fusing:
		team[0].set_decoy(null)
		team[1].set_decoy(null)
		
		for c in team[1].get_characters():
			team[1].remove_child(c)
			team[0].add_child(c)
			
			if order.fighter.team == 0 and c.character.partner_id != "":
				SaveState.set_flag("fused_with_" + c.character.partner_id, true)
				SaveState.stats.get_stat("fused_with").report_event(c.character.partner_id)
		
		order.fighter.status.refresh_stats()
		
		for effect in team[1].status.get_effects():
			team[1].status.remove_child(effect)
			team[0].status.add_effect_quietly(effect)
		team[0].status.refresh_stats()
		team[0].status.ap += team[1].status.ap
		battle.remove_child(team[1])
		var vacant_slot = team[1].slot
		battle.queue_animation(Bind.new(self, "_animate_fusion", [team, team[0].generate_transform_animation(), vacant_slot, team[0].slot]))
		team[0].status.update_decoy()
		battle.events.notify("fuse_ending", {"fighter":team[0]})
		
		battle.queue_animation(Bind.new(self, "_after_fusion", [order.fighter.team, team[0].get_species()]))
		
	battle.queue_hide_message()
	
	if is_fusing:
		if team[0].get_controller().has_node("BattleFusion"):
			battle.queue_animation(Bind.new(team[0].get_controller().get_node("BattleFusion"), "run"))
	
	battle.rand.pop()

func _after_fusion(team:int, species:Array):
	if team == 0:
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
		
		fighter.set_decoy(null)
		
		var new_fighter = FighterNode.new()
		new_fighter.team = fighter.team
		
		var char2 = fighter.get_characters()[1]
		fighter.remove_child(char2)
		new_fighter.add_child(char2)
		
		battle.add_child_below_node(fighter, new_fighter)
		new_fighter.set_preferred_slot()
		assert (new_fighter.slot != null)
		if new_fighter.slot.get_index() < fighter.slot.get_index():
			
			
			
			battle.move_child(new_fighter, fighter.get_index())
		
		fighter.status.refresh_stats()
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
			new_fighter.status.hp = new_fighter.status.max_hp
			
		new_fighter.get_controller().join_battle(false)
		
		if message != "":
			var name0 = fighter.get_name_with_team()
			var name1 = new_fighter.get_name_with_disambiguator()
			battle.queue_message(Loc.trf(message, [name0, name1]))
		
		var snap1 = fighter.status.get_snapshot()
		var snap2 = new_fighter.status.get_snapshot()
		var transform_anim = fighter.generate_transform_animation()
		var transform2_anim = new_fighter.generate_transform_animation()
		var enter_slot_anim = new_fighter.generate_enter_slot_animation()
		battle.queue_animation(Bind.new(self, "_animate_unfusion", [fighter, new_fighter, snap1, snap2, new_fighter.slot, transform_anim, transform2_anim, enter_slot_anim]))
		fighter.status.update_decoy()
		new_fighter.status.update_decoy()
		
		if heal_after_unfuse:
			var flinch = preload("res://data/status_effects/flinch.tres") as StatusEffect
			if not fighter.status.has_tag("flinch"):
				fighter.status.add_effect(flinch, 1)
			if not new_fighter.status.has_tag("flinch"):
				new_fighter.status.add_effect(flinch, 1)
		
		battle.events.notify("unfuse_ending", {"fighters":[fighter, new_fighter]})
		
		result = true
	
	battle.rand.pop()
	return result

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

func execute_move(order:BattleOrder):
	var user = order.fighter
	var move:BattleMove = order.order
	var arg = order.argument
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
