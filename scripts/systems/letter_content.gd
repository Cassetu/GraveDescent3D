class_name LetterContent

const LETTERS: Array[Dictionary] = [
	{
		"signature": "You",
		"text": ""
	},
	{
		"signature": "Corin",
		"text": ""
	},
	{
		"signature": "You",
		"text": ""
	},
	{
		"signature": "Corin",
		"text": ""
	},
	{
		"signature": "You",
		"text": ""
	},
	{
		"signature": "Corin",
		"text": ""
			},
	{
		"signature": "You",
		"text": ""
			},
	{
		"signature": "Corin",
		"text": ""
	},
]

static func get_letter(index: int) -> Dictionary:
	if index < 1 or index > LETTERS.size():
		return {}
	return LETTERS[index - 1]
