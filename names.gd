extends Node
var high_score := 0
const COP_DATA = [
	{
		"speed": 290.0,
		"damage": 8,
		"turn": 10.0,
		"sprite": "Fast"
	},
	{
		"speed": 210.0,
		"damage": 25,
		"turn": 5.0,
		"sprite": "Slow"
	},
	{
		"speed": 245.0,
		"damage": 15,
		"turn": 7.0,
		"sprite": "Medium"
	}
]
const FIRST_NAMES = [
	"Bob", "Gary", "Derek", "Nigel", "Barry", "Keith", "Trevor", "Clive", "Bazza", "Dazza",
	"Shazza", "Karen", "Doris", "Marge", "Edna", "Beryl", "Gladys", "Norma", "Vera", "Hilda",
	"Winston", "Desmond", "Clyde", "Leroy", "Tyrone", "Darnell", "Rufus", "Bubba", "Cooter", "Festus",
	"Clem", "Hank", "Earl", "Dale", "Merle", "Vern", "Otis", "Floyd", "Gomer", "Goober",
	"Plonker", "Rodney", "Trigger", "Boycie", "Marlene", "Del", "Grandad", "Raquel", "Cassandra", "Mike",
	"Blobfish", "Cornelius", "Archibald", "Reginald", "Humphrey", "Algernon", "Percival", "Mortimer", "Alistair", "Benedict",
	"Thaddeus", "Barnaby", "Ignatius", "Ptolemy", "Horatio", "Crispin", "Auberon", "Phineas", "Gideon", "Lemuel",
	"Chunk", "Sloth", "Mouth", "Data", "Mikey", "Brand", "Andy", "Stef", "Duckie", "Blane",
	"Ferris", "Cameron", "Sloane", "Jeanie", "Ed", "Rooney", "Grace", "Smee", "Noodler", "Starkey",
	"Grubby", "Stinky", "Smelly", "Lumpy", "Bumpy", "Crusty", "Rusty", "Dusty", "Musty", "Fusty",
	"Wally", "Buster", "Binky", "Skipper", "Flipper", "Nipper", "Ripper", "Tipper", "Dipper", "Kipper",
	"Meatball", "Noodle", "Dumpling", "Brisket", "Bristle", "Crumpet", "Biscuit", "Custard", "Pudding", "Sausage",
	"Wobble", "Bobble", "Gobble", "Cobble", "Hobble", "Nobble", "Dobble", "Lobble", "Robble", "Mobble",
	"Spud", "Turnip", "Parsnip", "Radish", "Sprout", "Swede", "Leek", "Squash", "Marrow", "Courgette",
	"Dingus", "Doofus", "Goofus", "Rufus", "Wufus", "Bufus", "Mufus", "Tufus", "Lufus", "Pufus",
]

const LAST_NAMES = [
	"Bumblebottom", "Fartsworth", "Snodgrass", "Plonker", "Bumblefoot", "Noodlearm", "Wobbleston", "Crumplehorn", "Dribbleston", "Squigglewick",
	"Puddingface", "Blobsworth", "Gribbleton", "Muddlethwaite", "Fumblefingers", "Numbskull", "Dunderhead", "Nincompoop", "Bumblethwaite", "Fumbleston",
	"McSausage", "O'Crumpet", "Von Wobble", "De Blobfish", "Le Plonker", "Van Dingus", "Mac Doofus", "Mc Goofus", "O'Noodle", "De La Spud",
	"Thunderpants", "Breezyknickers", "Windybottom", "Gassworth", "Trouser", "Legsworth", "Kneecap", "Elbow", "Shoulderpad", "Necksworth",
	"Twiddlewick", "Fiddlesticks", "Doodleston", "Scribbleston", "Squiggleston", "Wobbleston", "Bobbleston", "Gobbleston", "Cobbleston", "Hobbleston",
	"Crunchwick", "Munchwick", "Lunchwick", "Brunchwick", "Punchwick", "Hunchwick", "Bunchwick", "Dunchwick", "Funchwick", "Gunchwick",
	"Sprinkleton", "Twinkleston", "Wrinkleston", "Crinkleston", "Tinkleston", "Pinkleston", "Minkleston", "Rinkleston", "Linkleston", "Winkleston",
	"Giggleston", "Wiggleston", "Jiggleston", "Piggleston", "Biggleston", "Diggleston", "Figgleston", "Higgleston", "Liggleston", "Miggleston",
	"Bumbleshire", "Fumbleshire", "Tumbleshire", "Rumbleshire", "Humbleshire", "Jumbleshire", "Mumbleshire", "Dumbleshire", "Lumbleshire", "Cumbleshire",
	"Noodleston", "Doodleston", "Foodleston", "Goodleston", "Hoodleston", "Moodleston", "Roodleston", "Woodleston", "Broodleston", "Floodleston",
	"Puddington", "Cuddington", "Buddington", "Muddington", "Ruddington", "Studdington", "Thuddington", "Cluddington", "Fluddington", "Grudington",
	"Wobblechin", "Jigglychops", "Floppyears", "Droopyface", "Saggyarms", "Baggytrousers", "Scraggybeard", "Shaggyhead", "Raggycoat", "Taggyshirt",
	"Biscuitsworth", "Crumpetton", "Sconebury", "Muffinton", "Waferwick", "Crispyton", "Crackersworth", "Breadington", "Toastbury", "Jamsworth",
	"McFlurry", "O'Custard", "Von Sprinkle", "De Waffle", "Le Crepe", "Van Pancake", "Mac Syrup", "Mc Butter", "O'Maple", "De La Honey",
	"Grumbleston", "Mumbleston", "Stumbleston", "Tumbleston", "Rumbleston", "Humbleston", "Jumbleston", "Dumbleston", "Lumbleston", "Cumbleston",
]
func update_high_score(score: int) -> bool:
	if score > high_score:
		high_score = score
		return true  # new high score!
	return false
func random_name() -> String:
	var first = FIRST_NAMES[randi() % FIRST_NAMES.size()]
	var last  = LAST_NAMES[randi() % LAST_NAMES.size()]
	return first + " " + last
const SAVE_PATH = "user://save.cfg"

func save_high_score() -> void:
	var config = ConfigFile.new()
	config.set_value("scores", "high_score", high_score)
	config.save(SAVE_PATH)

func load_high_score() -> void:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		high_score = config.get_value("scores", "high_score", 0)

func _ready() -> void:
	Names.load_high_score()

var selected_car := 0

const CAR_DATA = [
	{
		"name": "Rusty Roller",
		"speed": 3,
		"handling": 5,
		"acceleration": 3,
		"drift": 1,
		"health": 200
	},
	{
		"name": "Street Shark",
		"speed": 5,
		"handling": 3,
		"acceleration": 4,
		"drift": 5,
		"health": 100
	},
	{
		"name": "Pizza Rocket",
		"speed": 4,
		"handling": 4,
		"acceleration": 5,
		"drift": 3,
		"health": 150
	}
]
