extends RefCounted

static func choice(text: String, action: String) -> Dictionary:
	return {"text":text,"action":action}

static func page(body: String, choices: Array) -> Dictionary:
	return {"body":body,"choices":choices}

static func dialogue(id: String, s: RefCounted) -> Dictionary:
	var f: Dictionary = s.flags
	match id:
		"mara":
			if f.won:
				return page("I saw it from the kitchen. A star, exactly where Northwatch used to be.\n\nAdela's caravan has already left. Tomorrow there will be strangers at these tables, complaining about the beds. Imagine that.\n\n[color=#dec48e]You brought back an ordinary tomorrow. That is no small thing.[/color]",[choice("A room, and something hot. [Rest & resupply]","mara_rest"),choice("Tell me what happened here.","mara_history"),choice("The road is yours again.","leave")])
			if not f.accepted:
				return page("Three nights ago, the Northwatch bell rang once. Then every lantern on the old road went out. Our supply cart never came home. Neither did the people with it.\n\nFollow the stone road north to the fallen toll. Find our stores, and look for Ilya, my scout. Osric has tonic and a blade to spare.\n\n[color=#dec48e]Bring the road back, if there is still a road to bring back.[/color]",[choice("I'll find your caravan. [Begin The Road North]","accept"),choice("What should I know before leaving?","tutorial"),choice("Let me look around first.","leave")])
			if f.prepared:
				return page("The oil is ready. The clapper is wrapped. Ilya will meet you at Northwatch. You can take a secured roadkeeper route from your journal.\n\n[color=#dec48e]Follow the stone road to Northwatch. Light the beacon and hold the courtyard.[/color]\n\nIf you find Tomas in the fen, tell him there is still a bed here. And if you pass the King's Cairn, tell my husband the inn is still here too.",[choice("A meal before I leave. [Free healing]","mara_rest"),choice("I'll keep the fire.","leave")])
			if f.oil and f.relic and not f.prepared:
				return page("Oil from a bandit's cupboard and a holy thing dug out of the dark. Roads have been built from stranger friendships.\n\nTake these supplies north. At Northwatch, set the clapper into the beacon and light the oil. The things that silenced the bell will come for you. Hold until the light catches.\n\n[color=#dec48e]Osric can improve your sword or coat before you leave. Come back breathing.[/color]",[choice("I'm ready. [Supplies + Northwatch defence unlocked]","prepare"),choice("Let me prepare a little more.","leave")])
			if f.supplies:
				return page("Ilya was right. Northwatch needs lamp oil from the Widow's Mill, west of the crossroads, and the old bell's clapper from the chapel to the east.\n\nThe mill folk are hungry. Sister Elian still keeps the chapel. Try speaking before you draw steel.\n\n[color=#dec48e]Bring both to Ilya at Northwatch, or come here if you want Osric's help. We will provision the final climb either way.[/color]",[choice("A meal and a short rest. [Free healing]","mara_rest"),choice("Tell me what happened here.","mara_history"),choice("I'll be back with both.","leave")])
			return page("Stay on the stone road until you see the broken towers. The cart should be just beyond them.\n\nUse your profession defence when a blade rises, then answer in the opening. If you tire, light a fire. And if you lose your way, open your journal. I marked the places that still have names.",[choice("I need a meal. [Free healing]","mara_rest"),choice("I'll follow the road.","leave")])
		"osric":
			var profession: String = s.profile.profession_id
			var implement := "sword" if profession=="warrior" else "consecrated staff" if profession=="cleric" else "firearm locks" if profession=="ranger" else "wand"
			var upgrade := "Reforge my sword. [32 to 43 damage]" if profession=="warrior" else "Bind my staff. [24 to 28 physical damage]" if profession=="cleric" else "Tune my firearm locks. [+5% shot damage]" if profession=="ranger" else "Bind my wand. [12 to 15 Dart damage]"
			return page("A sound implement is a promise you can keep. Steel, wood, brass: I know my trade.\n\nI can improve your %s with [color=#dec48e]4 scrap and 15 coins[/color]. Or stitch an ash-lined coat for [color=#dec48e]3 scrap and 12 coins[/color]: more vitality, less hurt. Deserters carry scrap. Old roadside chests have more.\n\nImplement: %s. Coat: %s.\nYour purse: %d coins / %d scrap." % [implement,"improved" if f.sword_upgrade else "road-worn","reinforced" if f.coat_upgrade else "travel-worn",s.inventory.gold,s.inventory.scrap],[choice(upgrade,"upgrade_sword"),choice("Reinforce my coat. [125 vitality + protection]","upgrade_coat"),choice("Another time.","leave")])
		"ilya":
			if f.oil and f.relic and f.scout and not f.prepared:
				return page("Mara sent provisions ahead. I took the north road while you recovered the clapper.\n\nSet the bronze into the beacon and light the oil. The things that silenced the bell will come. Hold until the light catches.\n\nYou can prepare here; there is no need to walk back to the inn.",[choice("Provision me for the defence. [3 tonics, 2 bread, 2 wood]","prepare"),choice("I need a moment.","leave")])
			if f.prepared and not f.won:
				return page("The provisions are yours. The beacon is just ahead. Remember the courtyard: hold your ground until the light catches.",[choice("I will keep the fire.","leave")])
			if f.courier_done:
				return page("You found Tomas? And the fever has broken? Good. I had almost stopped asking the road for good news.\n\nHe has a bed at Mara's, and his letters will reach their people once Northwatch burns again.\n\n[color=#dec48e]Letters for the Living is complete. The medicine reached Tomas and your reward is settled; you have my thanks as well.[/color]",[choice("What remains on the north road?","ilya_next"),choice("Keep his place by the fire.","leave")])
			if not f.supplies:
				return page("Mara sent you? Good. The cart is there, past the stones. Those aren't the mill folk attacking us. Deserters. They wear whatever coat they can steal.\n\nClear them out and take the stores. I'll tell you why the road went dark when I know you can stand your ground.",[choice("I'll recover the stores.","leave"),choice("Show me how to stay alive.","tutorial")])
			if not f.scout:
				return page("The beacon wasn't smashed. It was emptied. The old clapper is a ward, not merely a piece of bronze. Something carried it to the chapel's undercroft.\n\n[color=#dec48e]Go west for lamp oil, east for the clapper. Then meet me at Northwatch; Mara will send provisions ahead.[/color]\n\nCaptain Rook at the mill isn't beyond reason. Sister Elian knows the way below the chapel. Tomas, our courier, vanished near the lantern fen. If you find him, don't leave him there.",[choice("I'll relight Northwatch. [Scout's report + 25 XP]","scout_report"),choice("Who is Tomas?","courier_rumor"),choice("I'll think on it.","leave")])
			return page("West to the mill, east to the chapel. The north road joins them again below Northwatch.\n\nMy fire is yours. Spirits hate the warmth, but a warm fire is no substitute for a ready defence. Hold R beside it if you need to recover.",[choice("Tell me about the courier.","courier_rumor"),choice("Keep the road behind me.","leave")])
		"vesna":
			if f.herbs_done:
				return page("There now. The yellow flowers have done their work. These old hands may make it to another spring.\n\nIf you find moonwort in the fen, keep it for Tomas. The boy runs so fast that trouble has to wait in front of him.",[choice("Could you brew a tonic? [8 coins]","buy_tonic"),choice("Be well, Mother.","leave")])
			if s.inventory.yarrow>=3:
				return page("Three good stems. Still warm with the sun. Some folk gather flowers; others gather excuses.\n\nLet me put those to use. Two tonics for you, and a little coin. When the road is open again, I can send medicine north.",[choice("Here is the yarrow. [2 tonics + 20 coins + 40 XP]","give_yarrow"),choice("I need it for now.","leave")])
			return page("Don't trample the gold flowers, child. Yarrow grows where old fires slept, and it is the only thing that eases my shaking.\n\n[color=#dec48e]Bring me three stems from this grove[/color]. I'll brew something for your wounds in return.\n\nIn the fen, the pale flowers are moonwort. If someone is fevered, three stems will bring them back.",[choice("I'll gather three yarrow. [A Little Green Mercy]","herbalist_accept"),choice("Could you brew a tonic? [8 coins]","buy_tonic"),choice("I'll be careful where I step.","leave")])
		"rook":
			if f.oil:
				return page("There goes our last barrel. Make it count.\n\nWhen the beacon burns, send the first wagon to this mill. People can forgive a great deal with bread in their mouths.",[choice("I'll remember the mill.","leave")])
			if f.bargain:
				return page("A bargain is a bargain. The lamp oil is beside the wheel, behind the mill. Take it, and leave the grain alone.\n\nNobody here wants to be a bandit next winter.",[choice("You have my word.","leave")])
			return page("You look disappointed. Expecting a lord of thieves? I was a miller's husband before the road closed. These people were hungry before they were outlaws.\n\nYou want our lamp oil. I want [color=#dec48e]two loaves of bread[/color], or [color=#dec48e]12 coins[/color] to buy them.\n\nOr draw your sword and prove I was right to bar the door.",[choice("Share two loaves. [A bargain, not a battle]","rook_bread"),choice("Pay twelve coins for the oil.","rook_gold"),choice("Stand aside. I'll take what the road needs. [Fight]","rook_fight")])
		"sister":
			if f.relic:
				return page("You heard them, then. The people the bell could not save.\n\nA ward is a promise that the living will remember. Carry it north. Let the sound reach them again.\n\n[color=#dec48e]Ilya will meet you at Northwatch once you have the mill oil. Mara can still help at the inn.[/color]",[choice("Remember them for me.","leave"),choice("Can you tend my wounds?","chapel_heal")])
			return page("The clapper lies below us, in the underchapel. The dead sealed it away when the Bell Warden woke. Touch the standing stone beside the altar to descend.\n\n[color=#dec48e]Three seals guard it. Root, then Flame, then Bell.[/color]\nThe root remembers. The flame forgives. The bell calls home. Wake them in that order. A wrong note will silence them again.\n\nSpirits gather in the passages. Bring light, and leave yourself a way back.",[choice("I'll enter the underchapel. [Remember the sequence]","keeper_accept"),choice("Can you tend my wounds?","chapel_heal"),choice("Not yet.","leave")])
		"courier":
			if f.won and f.courier_done:
				return page("I delivered them. Every letter. The woman at the first farm cried before she even broke the seal.\n\nI don't know what to give you for carrying me out of that fen. Adela says there's a place on her wagon if the fever returns. Imagine that: a place to go.\n\nYou didn't just save a courier. You saved a dozen pieces of news.",[choice("Keep the letters moving.","leave")])
			if f.courier_done:
				return page("My legs remember what legs are for again. I'll wait by this fire until the road is safe.\n\nI thought the lights in the reeds were windows. I was so tired I thought someone had built a house for me. Thank you for being a real person.",[choice("I'll carry your letters onward.","leave")])
			if s.inventory.moonwort>=3:
				return page("Moonwort? Mother Vesna always said I'd need it one day. I thought she meant when I was old.\n\nPlease. The fever is making the lanterns sing.",[choice("Treat the fever. [Courier rescued + 35 coins + 60 XP]","save_courier"),choice("I'll come back.","leave")])
			return page("Don't follow the blue lights. I followed the blue lights.\n\nThere's a fever in this water. Mother Vesna said [color=#dec48e]three moonwort flowers[/color] will draw it out. They grow around these reeds. I can see them. I just can't stand.\n\nPlease don't let my letters be the last thing anyone finds.",[choice("I'll find the moonwort. [Letters for the Living]","courier_accept"),choice("Wait by the fire.","leave")])
		"merchant":
			return page("A lamp in a tower! You wouldn't believe how good that looks from a wagon seat.\n\nMara sent word. So did the mill. In a week this will be a road again, with wheel ruts and arguments and people late for supper.\n\n[color=#dec48e]The Hollow is connected again. Your expedition is complete.[/color]",[choice("Show me your medicines. [Tonic: 8 coins]","buy_tonic"),choice("Sell pelts and curios. [4 coins per pelt]","sell_curios"),choice("Welcome to Northwatch.","leave")])
	return page("The road is quiet.",[choice("Leave.","leave")])
