extends ContentInfo

var to_loaded:bool = false
var to_enable_fof_interactions = true
#
#var battlecontroller = preload("res://battle/BattleController.gd")
#
#func _init():
#    bestiarymenu.take_over_path("res://mods/tales_of_movepack/battle/BattleController_modified.gd")

var toaBattleController = preload("res://mods/tales_of_movepack/battle/ToBattleController.gd")

const MOD_STRINGS:Array = [
	preload("to_localization.en.translation"),
]
const MODUTILS: Dictionary = {
	"settings": [
		{
			"property": "to_enable_fof_interactions",
			"type": "toggle",
			"label": "Field of Fonon effects",
		}
	]
}

func _init():
	toaBattleController.take_over_path("res://battle/BattleController.gd")
	# Add translation strings
	for translation in MOD_STRINGS:
		TranslationServer.add_translation(translation)

	Console.register("toa_stickers", {
		"description":"Give stickers from Fields of Fonons", 
		"args":[], 
		"target":[self, "_console_to_stickers"]
	})

	SceneManager.preloader.connect("singleton_setup_completed", self, "_init_stickers")

func init_content():
	assert(DLC.has_mod("cat_modutils", 5))
	if not DLC.has_mod("cat_modutils", 5):
		OS.alert("Required mod dependency \"Mod Utils\" is missing or needs to be updated.", "Missing dependency!")
		return

	DLC.mods_by_id.cat_modutils.callbacks.connect_scene_ready("res://cutscenes/merchants/TownHall_VendingMachine_InteractionBehavior.tscn", self, "_on_VendingMachine1_ready")

func _on_VendingMachine1_ready(scene: Node) -> void:
	var exchange_menu = scene.get_child(0).get_child(0)
	var sticker_packs = Datatables.load("res://mods/tales_of_movepack/exchanges/booster_packs/").table
	for pack in sticker_packs:
			exchange_menu.exchanges.push_back(sticker_packs[pack])
			print("[TO] Added Sticker Pack: " + pack)

func _init_stickers():
	if to_loaded:
		return

	var battle_moves = Datatables.load("res://mods/tales_of_movepack/battle_moves/").table

	for move_name in battle_moves:
		_add_sticker(battle_moves[move_name], "to_" + move_name)#todo figure this naming

	to_loaded = true
	print("[TO] Loaded " + str(battle_moves.size()) + " stickers.")

func _add_sticker(sticker, sticker_id):
	# Add to global move list. Used in dev console, custom battle scene, etc.
	BattleMoves.moves.append(sticker)
	BattleMoves.by_id[sticker_id] = sticker

	# Add to primary sticker bucket. Used for "certain loot tables, Be Random, and AlephNull".
	BattleMoves.all_stickers.append(sticker)

	for tag in sticker.tags: 

		# Initializes tag if it's new.
		if not BattleMoves.by_tag.has(tag):
			BattleMoves.by_tag[tag] = []
		BattleMoves.by_tag[tag].push_back(sticker)

		# Add move to the tag pool
		if not BattleMoves.stickers_by_tag.has(tag):
			BattleMoves.stickers_by_tag[tag] = []
		BattleMoves.stickers_by_tag[tag].push_back(sticker)

		# Add move to shop pool, unless tagged unsellable
		if not sticker.tags.has("unsellable"):
			BattleMoves.sellable_stickers.push_back(sticker)
			if not BattleMoves.sellable_stickers_by_tag.has(tag):
				BattleMoves.sellable_stickers_by_tag[tag] = []
			BattleMoves.sellable_stickers_by_tag[tag].push_back(sticker)

	print("[TO] Added sticker: " + sticker_id)

func _console_to_stickers(force_rares:bool = false):
	var rand = Random.new()
	for move in BattleMoves.by_tag["to"]:#todo use this notation in my mod
		for _i in range(5):
			var rarity = null
			if force_rares:
				var dist = [
					{weight = 0.1, value = BaseItem.Rarity.RARITY_UNCOMMON}, 
					{weight = 0.025, value = BaseItem.Rarity.RARITY_RARE}
				]
				rarity = ItemFactory.rand_rarity(rand, dist)
			var sticker = ItemFactory.create_sticker(move, rand, rarity)
			SaveState.inventory.add_new_item(sticker, 1)
