//Mob vars
/mob/living
	var/arousalloss = 0									//How aroused the mob is.
	var/min_arousal = AROUSAL_MINIMUM_DEFAULT			//The lowest this mobs arousal will get. default = 0
	var/max_arousal = AROUSAL_MAXIMUM_DEFAULT			//The highest this mobs arousal will get. default = 100
	var/arousal_rate = AROUSAL_START_VALUE				//The base rate that arousal will increase in this mob.
	var/arousal_loss_rate = AROUSAL_START_VALUE			//How easily arousal can be relieved for this mob.
	var/canbearoused = FALSE					//Mob-level disabler for arousal. Starts off and can be enabled as features are added for different mob types.
	var/mb_cd_length = 5 SECONDS						//5 second cooldown for masturbating because fuck spam.
	var/mb_cd_timer = 0									//The timer itself

/mob/living/carbon/human
	canbearoused = TRUE

	var/saved_underwear = ""//saves their underwear so it can be toggled later
	var/saved_undershirt = ""
	var/saved_socks = ""
	var/hidden_underwear = FALSE
	var/hidden_undershirt = FALSE
	var/hidden_socks = FALSE

/mob/living/carbon/human/New()
	..()
	saved_underwear = underwear
	saved_undershirt = undershirt

//Species vars
/datum/species
	var/arousal_gain_rate = AROUSAL_START_VALUE //Rate at which this species becomes aroused
	var/arousal_lose_rate = AROUSAL_START_VALUE //Multiplier for how easily arousal can be relieved
	var/list/cum_fluids = list(/datum/reagent/consumable/semen)
	var/list/milk_fluids = list(/datum/reagent/consumable/milk)
	var/list/femcum_fluids = list(/datum/reagent/consumable/femcum)

//Mob procs
/mob/living/carbon/human/proc/underwear_toggle()
	set name = "Toggle undergarments"
	set category = "Object"
	if(ishuman(src))
		var/mob/living/carbon/human/humz = src
		var/confirm = input(src, "Select what part of your form to alter", "Undergarment Toggling", "Cancel") in list("Top", "Bottom", "Socks", "All", "Cancel")
		if(confirm == "Top")
			humz.hidden_undershirt = !humz.hidden_undershirt

		if(confirm == "Bottom")
			humz.hidden_underwear = !humz.hidden_underwear

		if(confirm == "Socks")
			humz.hidden_socks = !humz.hidden_socks

		if(confirm == "All")
			humz.hidden_undershirt = !humz.hidden_undershirt
			humz.hidden_underwear = !humz.hidden_underwear
			humz.hidden_socks = !humz.hidden_socks

		if(confirm == "Cancel")
			return
		src.update_body()

	else
		to_chat(src, "Humans only. How the fuck did you get this verb anyway.")

/mob/living/proc/handle_arousal()

/mob/living/carbon/handle_arousal()
	if(canbearoused && dna)
		var/datum/species/S
		S = dna.species
		if(S && !(SSmobs.times_fired % 36) && getArousalLoss() < max_arousal)//Totally stolen from breathing code. Do this every 36 ticks.
			adjustArousalLoss(arousal_rate * S.arousal_gain_rate)
			if(dna.features["exhibitionist"] && client)
				var/amt_nude = 0
				if(is_chest_exposed() && (getorganslot("breasts")))
					amt_nude++
				if(is_groin_exposed())
					if(getorganslot("penis"))
						amt_nude++
					if(getorganslot("vagina"))
						amt_nude++
				if(is_butt_exposed())
					if(getorganslot("anus"))
						amt_nude++
				if(amt_nude)
					var/watchers = 0
					for(var/mob/_M in view(world.view, src))
						var/mob/living/M = _M
						if(!istype(M))
							continue
						if(M.client && !M.stat && !M.eye_blind && (locate(src) in viewers(world.view,M)))
							watchers++
					if(watchers)
						adjustArousalLoss((amt_nude * watchers) + S.arousal_gain_rate)


/mob/living/proc/getArousalLoss()
	return arousalloss

/mob/living/proc/adjustArousalLoss(amount, updating_arousal=1)
	if(status_flags & GODMODE || !canbearoused)
		return FALSE
	arousalloss = CLAMP(arousalloss + amount, min_arousal, max_arousal)
	if(updating_arousal)
		updatearousal()

/mob/living/proc/setArousalLoss(amount, updating_arousal=1)
	if(status_flags & GODMODE || !canbearoused)
		return FALSE
	arousalloss = CLAMP(amount, min_arousal, max_arousal)
	if(updating_arousal)
		updatearousal()

/**
	* despite the name of this, it actually returns a number between 0 and 100
  */
/mob/living/proc/getPercentAroused()
	var/percentage = ((100 / max_arousal) * arousalloss)
	return percentage

/mob/living/proc/isPercentAroused(percentage)//returns true if the mob's arousal (measured in a percent of 100) is greater than the arg percentage.
	if(!isnum(percentage) || percentage > 100 || percentage < 0)
		CRASH("Provided percentage is invalid")
	if(getPercentAroused() >= percentage)
		return TRUE
	return FALSE

//H U D//
/mob/living/proc/updatearousal()
	update_arousal_hud()

/mob/living/carbon/updatearousal()
	. = ..()
	for(var/obj/item/organ/genital/G in internal_organs)
		if(istype(G))
			var/datum/sprite_accessory/S
			switch(G.type)
				if(/obj/item/organ/genital/penis)
					S = GLOB.cock_shapes_list[G.shape]
				if(/obj/item/organ/genital/testicles)
					S = GLOB.balls_shapes_list[G.shape]
				if(/obj/item/organ/genital/vagina)
					S = GLOB.vagina_shapes_list[G.shape]
				if(/obj/item/organ/genital/breasts)
					S = GLOB.breasts_shapes_list[G.shape]
			if(S?.alt_aroused)
				G.aroused_state = isPercentAroused(G.aroused_amount)
			if(getArousalLoss() >= isPercentAroused(33))
				G.aroused_state = TRUE
			else
				G.aroused_state = FALSE
			G.update_appearance()



/mob/living/proc/update_arousal_hud()
	return FALSE

/datum/species/proc/update_arousal_hud(mob/living/carbon/human/H)
	return FALSE

/mob/living/carbon/human/update_arousal_hud()
	if(!client || !hud_used)
		return FALSE
	if(dna.species.update_arousal_hud())
		return FALSE
	if(!canbearoused)
		hud_used.arousal.icon_state = ""
		return FALSE
	else
		if(hud_used.arousal)
			var/arousal_state = "arousal0"
			if(stat != DEAD)
				var/arousal_percent = getPercentAroused()
				var/arousal_rounded = FLOOR(arousal_percent, 10)
				arousal_state = "arousal[arousal_rounded]"
			hud_used.arousal.icon_state = arousal_state
			return TRUE

/obj/screen/arousal
	name = "arousal"
	icon_state = "arousal0"
	icon = 'modular_citadel/icons/obj/genitals/hud.dmi'
	screen_loc = ui_arousal

/obj/screen/arousal/Click()
	if(!isliving(usr))
		return FALSE
	if(isobserver(usr))
		return
	var/mob/living/M = usr
	if(M.canbearoused)
		ui_interact(usr)

/mob/living/proc/can_orgasm(arousal = 100)
	return src.getArousalLoss() >= arousal && ishuman(src) && src.has_dna()

/mob/living/proc/mob_climax()//This is just so I can test this shit without being forced to add actual content to get rid of arousal. Will be a very basic proc for a while.
	set name = "Masturbate"
	set category = "IC"
	if(canbearoused && !restrained() && !stat)
		if(mb_cd_timer <= world.time)
			//start the cooldown even if it fails
			mb_cd_timer = world.time + mb_cd_length
			if(getArousalLoss() >= isPercentAroused(33))//33% arousal or greater required
				src.visible_message("<span class='danger'>[src] starts masturbating!</span>", \
					"<span class='userdanger'>You start masturbating.</span>")
				if(do_after(src, 30, target = src))
					src.visible_message("<span class='danger'>[src] relieves [p_them()]self!</span>", \
						"<span class='userdanger'>You have relieved yourself.</span>")
					SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "orgasm", /datum/mood_event/orgasm)
					setArousalLoss(min_arousal)
			else
				to_chat(src, "<span class='notice'>You aren't aroused enough for that.</span>")


//These are various procs that we'll use later, split up for readability instead of having one, huge proc.
//For all of these, we assume the arguments given are proper and have been checked beforehand.
/mob/living/carbon/human/proc/mob_masturbate(obj/item/organ/genital/G, cover = FALSE, mb_time = 30) 
//Masturbation, keep it gender-neutral
	var/total_fluids = 0
	var/datum/reagents/fluid_source = null
	var/condomed = 0
	var/sounded = 0
	if(G.name == "penis")//if the select organ is a penis
		var/obj/item/organ/genital/penis/P = src.getorganslot("penis")
		if(P.condom) //if the penis is condomed
			condomed = 1
		if(P.sounding)
			sounded = 1
	if(G.producing) //Can it produce its own fluids, such as breasts?
		fluid_source = G.reagents
	else
		if(!G.linked_organ)
			to_chat(src, "<span class='warning'>Your [G.name] is unable to produce it's own fluids, it's missing the organs for it.</span>")
			return
		fluid_source = G.linked_organ.reagents
	total_fluids = fluid_source.total_volume
	if(mb_time)
		src.visible_message("<span class='love'>[src] starts to [G.masturbation_verb] [p_their()] [G.name].</span>", \
			"<span class='userlove'>You start to [G.masturbation_verb] your [G.name].</span>", \
			"<span class='userlove'>You start to [G.masturbation_verb] your [G.name].</span>")

	if(do_after(src, mb_time, target = src))
		if(total_fluids > 5 &&!condomed &&!sounded)
			fluid_source.reaction(src.loc, TOUCH, 1, 0)
			fluid_source.clear_reagents()
		if(!condomed && !sounded && !cover)
			src.visible_message("<span class='love'>[src] orgasms, cumming[istype(src.loc, /turf/open/floor) ? " onto [src.loc]" : ""]!</span>", \
				"<span class='userlove'>You cum[istype(src.loc, /turf/open/floor) ? " onto [src.loc]" : ""].</span>", \
				"<span class='userlove'>You have relieved yourself.</span>")

		if(!condomed &&!sounded && cover)//For when you want to make a mess of yourself.
			fluid_source.trans_to(src, total_fluids*G.fluid_transfer_factor)
			total_fluids -= total_fluids*G.fluid_transfer_factor
			if(total_fluids > 80) // now thats a big cum!
				var/mutable_appearance/cumoverlaylarge = mutable_appearance('hyperstation/icons/effects/cumoverlay.dmi')
				cumoverlaylarge.icon_state = "cum_large"
				src.add_overlay(cumoverlaylarge)

			if(total_fluids > 5)
				fluid_source.reaction(src.loc, TOUCH, 1, 0)
				var/mob/living/carbon/human/H = src
				if(H && G.name == "penis")
					H.cumdrip_rate += rand(5,10)
			fluid_source.clear_reagents()
			src.visible_message("<span class='love'>[src] climaxes over [p_their()] self, using [p_their()] [G.name]!</span>", \
				"<span class='userlove'>You orgasm over yourself, using your [G.name].</span>", \
				"<span class='userlove'>You have climaxed over something, using your [G.name].</span>")
			var/mutable_appearance/cumoverlay = mutable_appearance('hyperstation/icons/effects/cumoverlay.dmi')
			cumoverlay.icon_state = "cum_normal"
			src.add_overlay(cumoverlay)
		
		if(condomed) //condomed
			src.visible_message("<span class='love'>[src] orgasms, climaxing into [p_their()] condom </span>", \
							"<span class='userlove'>You cum into your condom.</span>", \
							"<span class='userlove'>You have relieved yourself.</span>")
		if(sounded) //sounded
			src.visible_message("<span class='love'>[src] orgasms, but the rod blocks anything from leaking out!</span>", \
							"<span class='userlove'>You cum with the rod inside.</span>", \
							"<span class='userlove'>You don't quite feel totally relieved.</span>")
		if(total_fluids > 0 &&condomed &&!sounded)
			src.condomclimax()

		SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "orgasm", /datum/mood_event/orgasm)
		if(G.can_climax)
			setArousalLoss(min_arousal)


/mob/living/carbon/human/proc/mob_climax_outside(obj/item/organ/genital/G, mb_time = 30, spillage = TRUE) //This is used for forced orgasms and other hands-free climaxes
	var/total_fluids = 0
	var/datum/reagents/fluid_source = null
	var/unable_to_come = FALSE

	if(G.producing) //Can it produce its own fluids, such as breasts?
		fluid_source = G.reagents
		total_fluids = fluid_source.total_volume
	else
		if(!G.linked_organ)
			unable_to_come = TRUE
		else
			fluid_source = G.linked_organ.reagents
			total_fluids = fluid_source.total_volume

	if(unable_to_come)
		src.visible_message("<span class='danger'>[src] shudders, their [G.name] unable to cum.</span>", \
							"<span class='userdanger'>Your [G.name] cannot cum, giving no relief.</span>", \
							"<span class='userdanger'>Your [G.name] cannot cum, giving no relief.</span>")
	else
		total_fluids = fluid_source.total_volume
		if(mb_time) //as long as it's not instant, give a warning
			src.visible_message("<span class='love'>[src] looks like they're about to cum.</span>", \
								"<span class='userlove'>You feel yourself about to orgasm.</span>", \
								"<span class='userlove'>You feel yourself about to orgasm.</span>")
		if(do_after(src, mb_time, target = src))
			if(spillage)
				if(total_fluids > 5)
					fluid_source.reaction(src.loc, TOUCH, 1, 0)

				fluid_source.clear_reagents()
				src.visible_message("<span class='love'>[src] orgasms[istype(src.loc, /turf/open/floor) ? ", spilling onto [src.loc]" : ""], with [p_their()] [G.name]!</span>", \
									"<span class='userlove'>You climax[istype(src.loc, /turf/open/floor) ? ", spilling onto [src.loc]" : ""] with your [G.name].</span>", \
									"<span class='userlove'>You climax using your [G.name].</span>")
			else //Else from spillage check, also note subtle text change
				src.visible_message("<span class='love'>[src] orgasms with [p_their()] [G.name]!</span>", \
									"<span class='userlove'>You climax with your [G.name].</span>", \
									"<span class='userlove'>You climax using your [G.name].</span>")

			SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "orgasm", /datum/mood_event/orgasm)
			if(G.can_climax)
				setArousalLoss(min_arousal)


/mob/living/carbon/human/proc/mob_climax_partner(obj/item/organ/genital/G, atom/partner, spillage = TRUE, impreg = FALSE,cover = FALSE,remote = FALSE, mb_time = 30) //Used for climaxing with any person
	if(isnoncarbon(partner)) // deny animals
		return
	var/total_fluids = 0
	var/datum/reagents/fluid_source = null
	if(G.producing) //Can it produce its own fluids, such as breasts?
		fluid_source = G.reagents
	else
		if(!G.linked_organ)
			to_chat(src, "<span class='warning'>Your [G.name] is unable to produce it's own fluids, it's missing the organs for it.</span>")
			return
	fluid_source = G.linked_organ.reagents
	total_fluids = fluid_source.total_volume
	if(mb_time && !remote) //Skip warning if this is an instant climax.
		src.visible_message("<span class='love'>[src] is about to climax with [partner]!</span>", \
			"<span class='userlove'>You're about to climax with [partner]!</span>", \
			"<span class='userlove'>You're preparing to climax with something!</span>")
	if(remote)
		src.visible_message("<span class='love'>[src] is about to climax with someone!</span>", \
			"<span class='userlove'>You're about to climax with someone!</span>", \
			"<span class='userlove'>You're preparing to climax with something!</span>")
	if(cover)//covering the partner in cum, this overrides other options.
		if(do_after(src, mb_time, target = src) && in_range(src, partner))
			fluid_source.trans_to(partner, total_fluids*G.fluid_transfer_factor)
			total_fluids -= total_fluids*G.fluid_transfer_factor
			if(total_fluids > 80 && iscarbon(partner)) // now thats a big cum!
				var/mutable_appearance/cumoverlaylarge = mutable_appearance('hyperstation/icons/effects/cumoverlay.dmi')
				cumoverlaylarge.icon_state = "cum_large"
				partner.add_overlay(cumoverlaylarge)
			if(total_fluids > 5)
				fluid_source.reaction(partner.loc, TOUCH, 1, 0)
				var/mob/living/carbon/human/H = partner
				if(H)
					H.cumdrip_rate += rand(5,10)
			fluid_source.clear_reagents()
			src.visible_message("<span class='love'>[src] climaxes over [partner], using [p_their()] [G.name]!</span>", \
				"<span class='userlove'>You orgasm over [partner], using your [G.name].</span>", \
				"<span class='userlove'>You have climaxed over something, using your [G.name].</span>")
			SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "orgasm", /datum/mood_event/orgasm)
			if(iscarbon(partner))
				var/mutable_appearance/cumoverlay = mutable_appearance('hyperstation/icons/effects/cumoverlay.dmi')
				cumoverlay.icon_state = "cum_normal"
				partner.add_overlay(cumoverlay)
			else
				partner.add_cum_overlay()
			setArousalLoss(min_arousal)
		if(G.can_climax)
			setArousalLoss(min_arousal)
	if(spillage && !cover)
		if(do_after(src, mb_time, target = src))
			if(!in_range(src, partner) && !remote)
				return
			fluid_source.trans_to(partner, total_fluids*G.fluid_transfer_factor)
			total_fluids -= total_fluids*G.fluid_transfer_factor
			if(total_fluids > 5)
				fluid_source.reaction(partner.loc, TOUCH, 1, 0)
				var/mob/living/carbon/human/H = partner
				if(H)
					H.cumdrip_rate += rand(5,10)
			fluid_source.clear_reagents()
			src.visible_message("<span class='love'>[src] climaxes with [partner][spillage ? ", overflowing and spilling":""], using [p_their()] [G.name]!</span>", \
								"<span class='userlove'>You orgasm with [partner][spillage ? ", spilling out of them":""], using your [G.name].</span>", \
								"<span class='userlove'>You have climaxed with someone[spillage ? ", spilling out of them":""], using your [G.name].</span>")
			SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "orgasm", /datum/mood_event/orgasm)
			SEND_SIGNAL(partner, COMSIG_ADD_MOOD_EVENT, "orgasm", /datum/mood_event/orgasm)
			if(G.can_climax)
				setArousalLoss(min_arousal)
	else //knots, portal fleshlights, and other non-spilling orgasms
		if(!cover)
			if(!remote && !in_range(src, partner))
				return
			if(do_after(src, mb_time, target = src))
				var/mob/living/carbon/H = partner
				if(!spillage && total_fluids > 80) //hyper inflation; requires a big cumshot to expand
					H.expand_belly(1)
				var/obj/item/organ/genital/penis/P = G
				if (P.condom)//condomed.
					src.condomclimax()
				else
					fluid_source.trans_to(partner, total_fluids)
				total_fluids = 0
				if(!remote)
					src.visible_message("<span class='love'>[src] climaxes with [partner], [p_their()] [G.name] spilling nothing!</span>", \
						"<span class='userlove'>You ejaculate with [partner], your [G.name] spilling nothing.</span>", \
						"<span class='userlove'>You have climaxed inside someone, your [G.name] spilling nothing.</span>")
				else
					src.visible_message("<span class='love'>[src] climaxes with someone, using [p_their()] [G.name]!</span>", \
						"<span class='userlove'>You ejaculate with someone, using your [G.name].</span>", \
						"<span class='userlove'>You have climaxed inside someone, using your [G.name].</span>")
					to_chat(partner, "<span class='userlove'>You feel someone ejaculate inside you.</span>")

				SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "orgasm", /datum/mood_event/orgasm)
				SEND_SIGNAL(partner, COMSIG_ADD_MOOD_EVENT, "orgasm", /datum/mood_event/orgasm)

				if(G.can_climax)
					setArousalLoss(min_arousal)
	//Hyper - antag code
	var/mob/living/carbon/partner_carbon = partner
	if(src.mind.special_role == ROLE_LEWD_TRAITOR)
		for(var/datum/objective/obj in src.mind.objectives)
			if (partner_carbon.mind == obj.target)
				partner_carbon.mind.sexed = TRUE //sexed
				to_chat(src, "<span class='userlove'>You feel deep satisfaction with yourself.</span>")
	//Hyper - impreg
	if(impreg)
		//Role them odds, only people with the dicks can send the chance to the person with the settings enabled at the momment.
		if(prob(partner_carbon.impregchance))
			var/obj/item/organ/genital/womb/W = partner_carbon.getorganslot("womb")
			if(W) //check if they have a womb.
				if (partner_carbon.breedable && !W.pregnant) //Dont get pregnant again, if you are pregnant.
					log_game("Debug: [partner] has been impregnated by [src]")
					to_chat(partner, "<span class='userlove'>You feel your hormones change, and a motherly instinct take over.</span>") //leting them know magic has happened.
					W.pregnant = 1
					if (HAS_TRAIT(partner, TRAIT_HEAT))
						SEND_SIGNAL(partner, COMSIG_ADD_MOOD_EVENT, "heat", /datum/mood_event/heat) //well done you perv.
						REMOVE_TRAIT(partner, TRAIT_HEAT, ROUNDSTART_TRAIT) //take the heat away, you satisfied it!
			 		//Make breasts produce quicker.
					var/obj/item/organ/genital/breasts/B = partner_carbon.getorganslot("breasts")
					if (B.fluid_mult < 0.5 && B)
						B.fluid_mult = 0.5

/mob/living/carbon/human/proc/mob_climax_partner_spillage(obj/item/organ/genital/picked_organ, mob/living/carbon/partner, impreg = FALSE)
	var/obj/item/organ/genital/penis/_penis = picked_organ
	if(picked_organ.name != "penis" || _penis.sounding || _penis.condom)
		mob_climax_partner(picked_organ, partner, FALSE, FALSE, FALSE)
		return
	var/_question = "Would your fluids spill outside?"
	var/_title = "Choose overflowing option"
	var/spillage = input(src, _question, _title, "Yes") as anything in list("Yes", "No")
	mob_climax_partner(picked_organ, partner, spillage == "Yes", impreg, FALSE)

/mob/living/carbon/human/proc/mob_fill_container(obj/item/organ/genital/G, obj/item/reagent_containers/container, mb_time = 30) //For beaker-filling, beware the bartender
	var/total_fluids = 0
	var/datum/reagents/fluid_source = null
	if(G.name == "penis")//if the select organ is a penis
		var/obj/item/organ/genital/penis/P = src.getorganslot("penis")
		if(P.condom) //if the penis is condomed
			to_chat(src, "<span class='warning'>You cannot fill containers when there is a condom over your [G.name].</span>")
			return
		if(P.sounding) //if the penis is sounded
			to_chat(src, "<span class='warning'>You cannot fill containers when there is a rod inside your [G.name].</span>")
			return
	if(G.producing) //Can it produce its own fluids, such as breasts?
		fluid_source = G.reagents
	else
		if(!G.linked_organ)
			to_chat(src, "<span class='warning'>Your [G.name] is unable to produce it's own fluids, it's missing the organs for it.</span>")
			return
		fluid_source = G.linked_organ.reagents
	total_fluids = fluid_source.total_volume

	if(!container) //Something weird happened
		to_chat(src, "<span class='warning'>You need a container to do this!</span>")
		return

	src.visible_message("<span class='love'>[src] starts to [G.masturbation_verb] their [G.name] over [container].</span>", \
						"<span class='userlove'>You start to [G.masturbation_verb] your [G.name] over [container].</span>", \
						"<span class='userlove'>You start to [G.masturbation_verb] your [G.name] over something.</span>")
	if(do_after(src, mb_time, target = src) && in_range(src, container))
		fluid_source.trans_to(container, total_fluids)
		src.visible_message("<span class='love'>[src] uses [p_their()] [G.name] to fill [container]!</span>", \
							"<span class='userlove'>You used your [G.name] and fill [container] with a total of [total_fluids]u's.</span>", \
							"<span class='userlove'>You have relieved some pressure.</span>")
		SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "orgasm", /datum/mood_event/orgasm)
		container.add_cum_overlay() //your aim is bad...
		if(G.can_climax)
			setArousalLoss(min_arousal)


/mob/living/carbon/human/proc/pick_masturbate_genitals()
	var/obj/item/organ/genital/ret_organ
	var/list/genitals_list = list()
	var/list/worn_stuff = get_equipped_items()

	for(var/obj/item/organ/genital/G in internal_organs)
		if(G.can_masturbate_with) //filter out what you can't masturbate with
			if(G.is_exposed(worn_stuff)) //Nude or through_clothing
				if(!G.dontlist)
					genitals_list += G
	if(genitals_list.len)
		ret_organ = input(src, "with what?", "Masturbate", null)  as null|obj in genitals_list
		return ret_organ
	return null //error stuff

/mob/living/carbon/human/proc/target_genitals(mob/living/carbon/human/T) //used for targeting others
	var/obj/item/organ/genital/ret_organ
	var/list/genitals_list = list()
	var/list/worn_stuff = get_equipped_items()

	for(var/obj/item/organ/genital/G in T.internal_organs)
		if(G.is_exposed(worn_stuff)) //Nude or through_clothing
			if(!G.dontlist)
				genitals_list += G
	if(genitals_list.len)
		ret_organ = input(src, "", "Genitals", null)  as null|obj in genitals_list
		return ret_organ
	return null //error stuff

/mob/living/carbon/human/proc/pick_climax_genitals()
	var/obj/item/organ/genital/ret_organ
	var/list/genitals_list = list()
	var/list/worn_stuff = get_equipped_items()

	for(var/obj/item/organ/genital/G in internal_organs)
		if(G.can_climax) //filter out what you can't masturbate with
			if(G.is_exposed(worn_stuff)) //Nude or through_clothing
				if(!G.dontlist)
					genitals_list += G
	if(genitals_list.len)
		ret_organ = input(src, "with what?", "Climax", null)  as null|obj in genitals_list
		return ret_organ
	return null //error stuff


/mob/living/carbon/human/proc/pick_partner(needs_exposed = TRUE)
	var/list/partners = list(src.pulling, src.pulledby)
	for(var/I in partners)
		if(!iscarbon(I))
			partners -= I
			continue
		if(!needs_exposed) 
			continue
		var/mob/living/carbon/C = I
		if(!C.exposed_genitals.len && !C.is_groin_exposed() && !C.is_chest_exposed())
			partners -= I
	if(!partners.len)
		return null
	return input(src, "With whom?", "Sexual partner", null) as null|anything in partners


/mob/living/carbon/human/proc/pick_climax_container()
	var/obj/item/reagent_containers/SC = null
	var/list/containers_list = list()

	for(var/obj/item/reagent_containers/container in held_items)
		if(container.is_open_container() || istype(container, /obj/item/reagent_containers/food/snacks))
			containers_list += container

	if(containers_list.len)
		SC = input(src, "Into or onto what?(Cancel for nowhere)", null)  as null|obj in containers_list
		if(SC)
			if(in_range(src, SC))
				return SC
	return null //If nothing correct, give null.


//Here's the main proc itself
/mob/living/carbon/human/mob_climax(forced_climax=FALSE) //Forced is instead of the other proc, makes you cum if you have the tools for it, ignoring restraints
	if(stat == DEAD) //corpses can't cum
		return
	if(mb_cd_timer > world.time)
		if(!forced_climax) //Don't spam the message to the victim if forced to come too fast
			to_chat(src, "<span class='warning'>You need to wait [DisplayTimeText((mb_cd_timer - world.time), TRUE)] before you can do that again!</span>")
		return
	mb_cd_timer = (world.time + mb_cd_length)
	if(canbearoused && has_dna())
		if(stat==2)
			to_chat(src, "<span class='warning'>You can't do that while dead!</span>")
			return
		if(forced_climax) //Something forced us to cum, this is not a masturbation thing and does not progress to the other checks
			for(var/obj/item/organ/O in internal_organs)
				if(istype(O, /obj/item/organ/genital))
					var/obj/item/organ/genital/G = O
					if(!G.can_climax) //Skip things like wombs and testicles
						continue
					var/mob/living/carbon/partner
					var/check_target
					var/list/worn_stuff = get_equipped_items()

					if(G.is_exposed(worn_stuff))
						if(src.pulling) //Are we pulling someone? Priority target, we can't be making option menus for this, has to be quick
							if(iscarbon(src.pulling)) //Don't fuck objects
								check_target = src.pulling
						else if(src.pulledby) //prioritise pulled over pulledby
							if(iscarbon(src.pulledby))
								check_target = src.pulledby
						//Now we should have a partner, or else we have to come alone
						if(check_target)
							var/mob/living/carbon/C = check_target
							if(C.exposed_genitals.len || C.is_groin_exposed() || C.is_chest_exposed()) //Are they naked enough?
								partner = C
						if(partner) //Did they pass the clothing checks?
							mob_climax_partner(G, partner, mb_time = 0) //Instant climax due to forced
							continue //You've climaxed once with this organ, continue on
					//not exposed OR if no partner was found while exposed, climax alone
					mob_climax_outside(G, mb_time = 0) //removed climax timer for sudden, forced orgasms
			//Now all genitals that could climax, have.
			//Since this was a forced climax, we do not need to continue with the other stuff
			return
		//If we get here, then this is not a forced climax and we gotta check a few things.
		if(stat==1) //No sleep-masturbation, you're unconscious.
			to_chat(src, "<span class='warning'>You must be conscious to do that!</span>")
			return
		if(getArousalLoss() < 33) //flat number instead of percentage
			to_chat(src, "<span class='warning'>You aren't aroused enough for that!</span>")
			return
		//Ok, now we check what they want to do.
		var/choice = input(src, "Select sexual activity", "Sexual activity:") in list("Masturbate", "Climax alone", "Climax with partner","Climax over partner", "Fill container", "Remove condom", "Remove sounding rod")
		switch(choice)
			if("Remove sounding rod")
				if(restrained(TRUE)) //TRUE ignores grabs
					to_chat(src, "<span class='warning'>You can't do that while restrained!</span>")
					return
				var/free_hands = get_num_arms()
				if(!free_hands)
					to_chat(src, "<span class='warning'>You need at least one free arm.</span>")
					return
				var/obj/item/organ/genital/penis/P = src.getorganslot("penis")
				if(!P.sounding)
					to_chat(src, "<span class='warning'>You don't have a rod inside!</span>")
					return
				if(P.sounding)
					to_chat(src, "<span class='warning'>You pull the rod off from the tip of your penis!</span>")
					src.removesounding()
					return
				return

			if("Remove condom")
				if(restrained(TRUE)) //TRUE ignores grabs
					to_chat(src, "<span class='warning'>You can't do that while restrained!</span>")
					return
				var/free_hands = get_num_arms()
				if(!free_hands)
					to_chat(src, "<span class='warning'>You need at least one free arm.</span>")
					return
				var/obj/item/organ/genital/penis/P = src.getorganslot("penis")
				if(!P.condom)
					to_chat(src, "<span class='warning'>You don't have a condom on!</span>")
					return
				if(P.condom)
					to_chat(src, "<span class='warning'>You tug the condom off the end of your penis!</span>")
					src.removecondom()
					return
				return

			if("Masturbate")
				if(restrained(TRUE)) //TRUE ignores grabs
					to_chat(src, "<span class='warning'>You can't do that while restrained!</span>")
					return
				var/free_hands = get_num_arms()
				if(!free_hands)
					to_chat(src, "<span class='warning'>You need at least one free arm.</span>")
					return
				for(var/helditem in held_items)//how many hands are free
					if(isobj(helditem))
						free_hands--
				if(free_hands <= 0)
					to_chat(src, "<span class='warning'>You're holding too many things.</span>")
					return
				//We got hands, let's pick an organ
				var/obj/item/organ/genital/picked_organ
				picked_organ = pick_masturbate_genitals()
				if(picked_organ)
					mob_masturbate(picked_organ)
					return
				else //They either lack organs that can masturbate, or they didn't pick one.
					to_chat(src, "<span class='warning'>You cannot masturbate without choosing genitals.</span>")
					return

			if("Climax alone")
				if(restrained(TRUE)) //TRUE ignores grabs
					to_chat(src, "<span class='warning'>You can't do that while restrained!</span>")
					return
				var/free_hands = get_num_arms()
				if(!free_hands)
					to_chat(src, "<span class='warning'>You need at least one free arm.</span>")
					return
				for(var/helditem in held_items)//how many hands are free
					if(isobj(helditem))
						free_hands--
				if(free_hands <= 0)
					to_chat(src, "<span class='warning'>You're holding too many things.</span>")
					return
				//We got hands, let's pick an organ
				var/obj/item/organ/genital/picked_organ
				picked_organ = pick_climax_genitals()
				if(picked_organ)
					mob_climax_outside(picked_organ)
					return
				else //They either lack organs that can masturbate, or they didn't pick one.
					to_chat(src, "<span class='warning'>You cannot climax without choosing genitals.</span>")
					return

			if("Climax with partner")
				//We need no hands, we can be restrained and so on, so let's pick an organ
				var/obj/item/organ/genital/picked_organ
				picked_organ = pick_climax_genitals()
				if(!picked_organ)
					to_chat(src, "<span class='warning'>You cannot climax without choosing genitals.</span>")
					return
				var/mob/living/carbon/partner = pick_partner() //Get someone
				if(!partner)
					to_chat(src, "<span class='warning'>You cannot do this alone.</span>")
					return
				var/obj/item/organ/genital/penis/P = picked_organ
				var/impreg = "No"
				if(partner.breedable && picked_organ.name == "penis" && !P.condom && !P.sounding)
					var/impreg_question = "Would this action carry the risk of pregnancy?"
					var/impreg_title = "Choose a option"
					impreg = input(src, impreg_question, impreg_title, "Yes") as anything in list("Yes", "No")
				mob_climax_partner_spillage(picked_organ, partner, impreg == "Yes")

			if("Climax over partner")
				var/obj/item/organ/genital/picked_organ
				picked_organ = pick_climax_genitals()
				if(picked_organ)
					var/mob/living/carbon/partner = pick_partner(FALSE) //Get your partner, clothed or not.
					if(partner)
						mob_climax_partner(picked_organ, partner, FALSE, FALSE, TRUE)
					else
						to_chat(src, "<span class='warning'>You cannot do this alone.</span>")

			if("Fill container")
				//We'll need hands and no restraints.
				if(restrained(TRUE)) //TRUE ignores grabs
					to_chat(src, "<span class='warning'>You can't do that while restrained!</span>")
					return
				var/free_hands = get_num_arms()
				if(!free_hands)
					to_chat(src, "<span class='warning'>You need at least one free arm.</span>")
					return
				for(var/helditem in held_items)//how many hands are free
					if(isobj(helditem))
						free_hands--
				if(free_hands <= 0)
					to_chat(src, "<span class='warning'>You're holding too many things.</span>")
					return
				//We got hands, let's pick an organ
				var/obj/item/organ/genital/picked_organ
				picked_organ = pick_climax_genitals() //Gotta be climaxable, not just masturbation, to fill with fluids.
				if(picked_organ)
					//Good, got an organ, time to pick a container
					var/obj/item/reagent_containers/fluid_container = pick_climax_container()
					if(fluid_container)
						mob_fill_container(picked_organ, fluid_container)
						return
					else
						to_chat(src, "<span class='warning'>You cannot do this without anything to fill.</span>")
						return
				else //They either lack organs that can climax, or they didn't pick one.
					to_chat(src, "<span class='warning'>You cannot fill anything without choosing genitals.</span>")
					return
			else //Somehow another option was taken, maybe something interrupted the selection or it was cancelled
				return //Just end it in that case.

