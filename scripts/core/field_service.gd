extends RefCounted
# All field mutations validate before spending items or moving individuals.
static func deposit(session: RefCounted, index: int) -> String:
	if index < 0 or index >= session.party.size(): return "INVALID MEMBER."
	var healthy := 0
	for i in range(session.party.size()):
		if i != index and session.party[i].hp > 0: healthy += 1
	if healthy == 0: return "KEEP A HEALTHY PARTNER."
	session.storage.append(session.party.pop_at(index))
	return "MOVED TO STORAGE."

static func withdraw(session: RefCounted, index: int, target: int) -> String:
	if index < 0 or index >= session.storage.size(): return "STORAGE IS EMPTY."
	if session.party.size() < session.PARTY_LIMIT:
		session.party.append(session.storage.pop_at(index))
		return "JOINED THE PARTY."
	if target < 0 or target >= session.party.size(): return "CHOOSE A PARTY SLOT FIRST."
	var healthy: bool = session.storage[index].hp > 0
	for i in range(session.party.size()):
		if i != target: healthy = healthy or session.party[i].hp > 0
	if not healthy: return "KEEP A HEALTHY PARTNER."
	var previous: RefCounted = session.party[target]
	session.party[target] = session.storage[index]
	session.storage[index] = previous
	return "EXCHANGED WITH PARTY SLOT %s." % (target + 1)

static func balm(session: RefCounted, index: int) -> String:
	if index < 0 or index >= session.party.size(): return "INVALID MEMBER."
	var monster: RefCounted = session.party[index]
	var maximum: int = monster.max_hp(session.catalog.species[monster.species_id])
	if monster.hp <= 0: return "FAINTED PARTNERS NEED TOWN REST."
	if monster.hp >= maximum: return "HEALTH IS ALREADY FULL."
	if session.inventory.balm <= 0: return "NO BALM REMAINING."
	monster.hp = mini(maximum, monster.hp + session.catalog.items.balm.value)
	session.inventory.balm -= 1
	return "BALM RESTORED HEALTH."

static func rest(session: RefCounted, map_id: String) -> String:
	if map_id != "town": return "REST IS AVAILABLE IN TOWN."
	for monster: RefCounted in session.party + session.storage:
		monster.hp = monster.max_hp(session.catalog.species[monster.species_id])
	# Town lending supplies restore a baseline, never delete surplus.
	session.inventory.charm = maxi(session.inventory.charm, 12)
	session.inventory.balm = maxi(session.inventory.balm, 6)
	return "RESTED ALL. SUPPLIES REPLENISHED."
