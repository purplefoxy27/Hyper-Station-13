// CARDS AGAINST SPESS
// This is a parody of Cards Against Humanity (https://en.wikipedia.org/wiki/Cards_Against_Humanity)
// which is licensed under CC BY-NC-SA 2.0, the full text of which can be found at the following URL:
// https://creativecommons.org/licenses/by-nc-sa/2.0/legalcode
// Original code by Zuhayr, Polaris Station, ported with modifications 
// April 2022: modified by sarcoph for hyperstation

/obj/item/toy/cards/deck/cas
	name = "\improper CAS deck (white)"
	desc = "A deck for the game Cards Against Spess, still popular after all these centuries. Warning: may include traces of broken fourth wall. This is the white deck."
	icon = 'icons/obj/toy.dmi'
	icon_state = "deck_caswhite_full"
	deckstyle = "caswhite"
	var/card_face = "cas_white"
	var/blanks = 25
	var/decksize = 150
	var/card_text_file = "strings/cas_white.txt"

/obj/item/toy/cards/deck/cas/black
	name = "\improper CAS deck (black)"
	desc = "A deck for the game Cards Against Spess, still popular after all these centuries. Warning: may include traces of broken fourth wall. This is the black deck."
	icon_state = "deck_casblack_full"
	deckstyle = "casblack"
	card_face = "cas_black"
	blanks = 0
	decksize = 50
	card_text_file = "strings/cas_black.txt"

/obj/item/toy/cards/deck/cas/populate_deck()
	var/static/list/cards_against_space = list(
		"cas_white" = world.file2list("strings/cas_white.txt"),
		"cas_black" = world.file2list("strings/cas_black.txt")
	)
	cards = cards_against_space[card_face]
	var/list/possiblecards = cards.Copy()
	if(possiblecards.len < decksize) // sanity check
		decksize = (possiblecards.len - 1)
	var/list/randomcards = list()
	for(var/x in 1 to decksize)
		randomcards += pick_n_take(possiblecards)
	for(var/x in 1 to randomcards.len)
		var/cardtext = randomcards[x]
		cards += list(list(
			"name" = cardtext,
			"icon_state" = src.card_face,
			"rotation" = null,
			"face_up" = null
		))
	if(!blanks)
		cards = shuffle(cards) 
		return
	for(var/x in 1 to blanks)
		cards += list(list(
			"name" = "Blank Card",
			"icon_state" = "cas_white",
			"rotation" = null,
			"face_up" = null
		))
	cards = shuffle(cards) // distribute blank cards throughout deck

/obj/item/toy/cards/deck/cas/DrawOneCard(list/card_indices)
	var/obj/item/toy/cards/singlecard/cas/S = new/obj/item/toy/cards/singlecard/cas(usr.loc)
	var/_card = cards[card_indices[1]]
	if(_card["name"] == "Blank Card")
		S.blank = TRUE
	S.name = _card["name"]
	S.icon_state = _card["icon_state"]
	S.parentdeck = src
	cards -= list(_card)
	update_icon()
	return S

/obj/item/toy/cards/deck/cas/update_icon()
	if(cards.len < 26)
		icon_state = "deck_[deckstyle]_low"

/obj/item/toy/cards/singlecard/cas
	name = "CAS card"
	desc = "A CAS card."
	icon_state = "cas_white"
	var/card_face = "cas_white"
	var/blank = 0
	var/buffertext = "A funny bit of text."

/obj/item/toy/cards/singlecard/cas/examine(mob/user)
	. = ..()
	if (!face_up)
		. += "<span class='notice'>The card is face down.</span>"
	else if (blank)
		. += "<span class='notice'>The card is blank. Write on it with a pen.</span>"
	else
		. += "<span class='notice'>The card reads: [name]</span>"

/obj/item/toy/cards/singlecard/cas/update_icon()
	if(face_up)
		icon_state = "[card_face]_flipped"
		name = card["name"]
	else
		icon_state = "[card_face]"

/obj/item/toy/cards/singlecard/cas/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/pen))
		if(!user.is_literate())
			to_chat(user, "<span class='notice'>You scribble illegibly on [src]!</span>")
			return
		if(!blank)
			to_chat(user, "You cannot write on that card.")
			return
		var/cardtext = stripped_input(user, "What do you wish to write on the card?", "Card Writing", "", 50)
		if(!cardtext || !user.canUseTopic(src, BE_CLOSE))
			return
		name = cardtext
		buffertext = cardtext
		blank = 0
