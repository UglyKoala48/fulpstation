/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//			TG OVERWRITES

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/// Gives Curators their abilities
/datum/outfit/job/curator/post_equip(mob/living/carbon/human/user, visualsOnly = FALSE)
	. = ..()

	ADD_TRAIT(user, TRAIT_BLOODSUCKER_HUNTER, JOB_TRAIT)

/// Prevents using a Memento Mori
/obj/item/clothing/neck/necklace/memento_mori/memento(mob/living/carbon/human/user)
	if(IS_BLOODSUCKER(user))
		to_chat(user, span_warning("The Memento notices your undead soul, and refuses to react.."))
		return
	return ..()

/datum/species/jelly/slime/spec_life(mob/living/carbon/human/user)
	// Prevents Slimeperson 'gaming
	if(IS_BLOODSUCKER(user))
		return
	return ..()

/// Prevents Bloodsuckers from naturally regenerating Blood - Even while on masquerade
/mob/living/carbon/human/handle_blood(delta_time, times_fired)
	if(mind && IS_BLOODSUCKER(src))
		return
	/// For Vassals -- Bloodsuckers get this removed while on Masquerade, so we don't want to remove the check above.
	if(HAS_TRAIT(src, TRAIT_NOPULSE))
		return
	return ..()

/mob/living/carbon/human/natural_bodytemperature_stabilization(datum/gas_mixture/environment, delta_time, times_fired)
	// Return 0 as your natural temperature. Species proc handle_environment() will adjust your temperature based on this.
	if(HAS_TRAIT(src, TRAIT_COLDBLOODED))
		return 0
	return ..()

// Used when analyzing a Bloodsucker, Masquerade will hide brain traumas (Unless you're a Beefman)
/mob/living/carbon/get_traumas()
	if(!mind)
		return ..()
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = IS_BLOODSUCKER(src)
	if(bloodsuckerdatum && HAS_TRAIT(src, TRAIT_MASQUERADE) && !isbeefman(src))
		return
	return ..()

// Used to keep track of how much Blood we've drank so far
/mob/living/carbon/human/get_status_tab_items()
	. = ..()
	if(mind)
		var/datum/antagonist/bloodsucker/bloodsuckerdatum = mind.has_antag_datum(/datum/antagonist/bloodsucker)
		if(bloodsuckerdatum)
			. += ""
			. += "Blood Drank: [bloodsuckerdatum.total_blood_drank]"


// INTEGRATION: Adding Procs and Datums to existing "classes" //

// EXAMINING
/mob/living/carbon/human/proc/ReturnVampExamine(mob/living/viewer)
	if(!mind || !viewer.mind)
		return ""
	// Target must be a Vamp
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = mind.has_antag_datum(/datum/antagonist/bloodsucker)
	if(!bloodsuckerdatum)
		return ""
	// Viewer is Target's Vassal?
	if(viewer.mind.has_antag_datum(/datum/antagonist/vassal) in bloodsuckerdatum.vassals)
		var/returnString = "\[<span class='warning'><EM>This is your Master!</EM></span>\]"
		var/returnIcon = "[icon2html('fulp_modules/features/antagonists/bloodsuckers/icons/vampiric.dmi', world, "bloodsucker")]"
		returnString += "\n"
		return returnIcon + returnString
	// Viewer not a Vamp AND not the target's vassal?
	if(!viewer.mind.has_antag_datum((/datum/antagonist/bloodsucker)) && !(viewer in bloodsuckerdatum.vassals))
		if(!(HAS_TRAIT(viewer, TRAIT_BLOODSUCKER_HUNTER) && bloodsuckerdatum.broke_masquerade))
			return ""
	// Default String
	var/returnString = "\[<span class='warning'><EM>[bloodsuckerdatum.ReturnFullName(1)]</EM></span>\]"
	var/returnIcon = "[icon2html('fulp_modules/features/antagonists/bloodsuckers/icons/vampiric.dmi', world, "bloodsucker")]"

	// In Disguise (Veil)?
	//if (name_override != null)
	//	returnString += "<span class='suicide'> ([real_name] in disguise!) </span>"

	//returnString += "\n"  Don't need spacers. Using . += "" in examine.dm does this on its own.
	return returnIcon + returnString

/mob/living/carbon/human/proc/ReturnVassalExamine(mob/living/viewer)
	if(!mind || !viewer.mind)
		return ""
	// Target must be a Vassal
	var/datum/antagonist/vassal/vassaldatum = mind.has_antag_datum(/datum/antagonist/vassal)
	if(!vassaldatum)
		return ""
	// Default String
	var/returnString = "\[<span class='warning'>"
	var/returnIcon = ""
	// Vassals and Bloodsuckers recognize eachother, while Monster Hunters can see Vassals.
	if(IS_BLOODSUCKER(viewer) || IS_VASSAL(viewer) || IS_MONSTERHUNTER(viewer))
		// Am I Viewer's Vassal?
		if(vassaldatum?.master.owner == viewer.mind)
			returnString += "This [dna.species.name] bears YOUR mark!"
			returnIcon = "[icon2html('fulp_modules/features/antagonists/bloodsuckers/icons/vampiric.dmi', world, "vassal")]"
		// Am I someone ELSE'S Vassal?
		else if(IS_BLOODSUCKER(viewer) || IS_MONSTERHUNTER(viewer))
			returnString +=	"This [dna.species.name] bears the mark of <span class='boldwarning'>[vassaldatum.master.ReturnFullName(vassaldatum.master.owner.current,TRUE)][vassaldatum.master.broke_masquerade ? " who has broken the Masquerade" : ""]</span>"
			returnIcon = "[icon2html('fulp_modules/features/antagonists/bloodsuckers/icons/vampiric.dmi', world, "vassal_grey")]"
		// Are you serving the same master as I am?
		else if(viewer.mind.has_antag_datum(/datum/antagonist/vassal) in vassaldatum?.master.vassals)
			returnString += "[p_they(TRUE)] bears the mark of your Master"
			returnIcon = "[icon2html('fulp_modules/features/antagonists/bloodsuckers/icons/vampiric.dmi', world, "vassal")]"
		// You serve a different Master than I do.
		else
			returnString += "[p_they(TRUE)] bears the mark of another Bloodsucker"
			returnIcon = "[icon2html('fulp_modules/features/antagonists/bloodsuckers/icons/vampiric.dmi', world, "vassal_grey")]"
	else
		return ""

	returnString += "</span>\]" // \n"  Don't need spacers. Using . += "" in examine.dm does this on its own.
	return returnIcon + returnString

/// Am I "pale" when examined? - Bloodsuckers on Masquerade will hide this.
/mob/living/carbon/human/proc/ShowAsPaleExamine(mob/user, apparent_blood_volume)
	if(!mind)
		return BLOODSUCKER_HIDE_BLOOD
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = mind.has_antag_datum(/datum/antagonist/bloodsucker)
	// Not a Bloodsucker?
	if(!bloodsuckerdatum)
		return BLOODSUCKER_HIDE_BLOOD
	// Blood level too low to be hidden?
	if(apparent_blood_volume <= BLOOD_VOLUME_BAD || bloodsuckerdatum.frenzied)
		return BLOODSUCKER_HIDE_BLOOD
	// Special check: Nosferatu will always be Pale Death
	if(bloodsuckerdatum.my_clan == CLAN_NOSFERATU)
		return "<b>[p_they(TRUE)] look[p_s()] as pale as a Vampire, what the fuck?!\n"
	if(HAS_TRAIT(src, TRAIT_MASQUERADE))
		return BLOODSUCKER_HIDE_BLOOD
	switch(apparent_blood_volume)
		if(BLOOD_VOLUME_OKAY to BLOOD_VOLUME_SAFE)
			return "[p_they(TRUE)] [p_have()] pale skin.\n"
		if(BLOOD_VOLUME_BAD to BLOOD_VOLUME_OKAY)
			return "<b>[p_they(TRUE)] look[p_s()] like pale death.</b>\n"

/datum/outfit/bloodsucker_outfit
	name = "Bloodsucker outfit (Preview only)"
	suit = /obj/item/clothing/suit/dracula

/datum/outfit/bloodsucker_outfit/post_equip(mob/living/carbon/human/enrico, visualsOnly=FALSE)
	enrico.hairstyle = "Undercut"
	enrico.hair_color = "FFF"
	enrico.skin_tone = "african2"
	enrico.eye_color_left = "#663300"
	enrico.eye_color_right = "#663300"

	enrico.update_hair()
	enrico.update_body()
