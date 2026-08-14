class_name LetterContent

const LETTERS: Array[Dictionary] = [
	{
		"signature": "You",
		"text": "I sealed the door today. I told everyone Corin wandered off. I don't think I did the right thing.",
	},
	{
		"signature": "Corin",
		"text": "Three days now. I keep hoping the door opens. It doesn't.",
	},
	{
		"signature": "You",
		"text": "Mother asked me again if I've heard anything. I said no. I keep saying no.",
	},
	{
		"signature": "Corin",
		"text": "I found water further down. I'm not dying today at least.",
	},
	{
		"signature": "You",
		"text": "I keep telling myself they wouldn't have survived anyway. I don't believe that anymore.",
	},
	{
		"signature": "Corin",
		"text": "I don't think they're coming back for me. I think they meant to leave me here.",
	},
]

static func get_letter(index: int) -> Dictionary:
	if index < 1 or index > LETTERS.size():
		return {}
	return LETTERS[index - 1]
