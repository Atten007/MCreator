/*
 * MCreator (https://mcreator.net/)
 * Copyright (C) 2012-2020, Pylo
 * Copyright (C) 2020-2022, Pylo, opensource contributors
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

package net.mcreator.minecraft;

import net.mcreator.element.BaseType;
import net.mcreator.element.ModElementType;
import net.mcreator.element.parts.MItemBlock;
import net.mcreator.element.types.LivingEntity;
import net.mcreator.element.types.interfaces.IPOIProvider;
import net.mcreator.generator.mapping.NameMapper;
import net.mcreator.ui.minecraft.states.PropertyData;
import net.mcreator.workspace.Workspace;
import net.mcreator.workspace.elements.ModElement;
import net.mcreator.workspace.elements.SoundElement;
import net.mcreator.workspace.elements.VariableType;
import net.mcreator.workspace.elements.VariableTypeLoader;
import net.mcreator.workspace.resources.Animation;

import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.function.Predicate;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class ElementUtil {

	/**
	 * Provides a predicate to check the type of data list entries
	 *
	 * @param type The type that the entry has to match
	 * @return A predicate that checks if the type matches the parameter
	 */
	public static Predicate<DataListEntry> typeMatches(String... type) {
		if (type.length == 1) {
			return e -> type[0].equals(e.getType());
		} else {
			return e -> Arrays.asList(type).contains(e.getType());
		}
	}

	/**
	 * Loads a list of entries, with optional custom entries from the given mod element types,
	 * and with an optional filter for the entry type.
	 *
	 * <p>NOTE: custom entries cannot specify a type yet, so the type filter will remove any custom entry</p>
	 *
	 * @param workspace            The current workspace
	 * @param dataList             The datalist from which to load the entries
	 * @param typeFilter           If present, only entries whose type matches this parameter are loaded
	 * @param customEntryProviders The string id of the mod element types that provide custom entries
	 * @return All entries from the given data list and the given mod element types, matching the optional filter
	 */
	public static List<DataListEntry> loadDataListAndElements(Workspace workspace, String dataList,
			@Nullable String typeFilter, @Nullable String... customEntryProviders) {
		List<DataListEntry> retval = new ArrayList<>();

		// We add custom entries before normal ones, so that they are on top even if the list isn't sorted
		if (customEntryProviders != null) {
			retval.addAll(getCustomElements(workspace,
					me -> Arrays.asList(customEntryProviders).contains(me.getTypeString())));
		}
		retval.addAll(DataListLoader.loadDataList(dataList));

		Stream<DataListEntry> retvalStream = retval.stream();
		if (typeFilter != null) {
			retvalStream = retvalStream.filter(typeMatches(typeFilter));
		}
		retval = retvalStream.filter(e -> e.isSupportedInWorkspace(workspace)).collect(Collectors.toList());
		retval.sort(DataListEntry.getComparator(workspace, retval));
		return retval;
	}

	/**
	 * Loads all items (also blocks if they have item representation), but without those
	 * that are wildcard elements to subtypes (wood: oak wood, cherry wood, ...)
	 * so only oak wood, cherry wood, ... are loaded, without wildcard wood element.
	 * This will not load blocks without item representation (example fire, water, ...).
	 *
	 * @return All Blocks and Items from both Minecraft and custom elements with or without metadata
	 */
	public static List<MCItem> loadBlocksAndItems(Workspace workspace) {
		List<MCItem> elements = new ArrayList<>();
		workspace.getModElements().forEach(modElement -> elements.addAll(modElement.getMCItems()));
		elements.sort(MCItem.getComparator(workspace, elements)); // sort custom elements
		elements.addAll(
				DataListLoader.loadDataList("blocksitems").stream().map(e -> (MCItem) e).filter(MCItem::hasNoSubtypes)
						.toList());
		return elements.stream().filter(typeMatches("block", "item")).filter(e -> e.isSupportedInWorkspace(workspace))
				.collect(Collectors.toList());
	}

	/**
	 * Loads all items (also blocks if they have item representation), including elements
	 * that are wildcard elements to subtypes (wood: oak wood, cherry wood, ...).
	 * This will not load blocks without item representation (example fire, water, ...).
	 *
	 * @return All Blocks and Items from both Minecraft and custom elements with or without metadata
	 */
	public static List<MCItem> loadBlocksAndItemsAndTags(Workspace workspace) {
		List<MCItem> elements = new ArrayList<>();
		workspace.getModElements().forEach(modElement -> elements.addAll(modElement.getMCItems()));
		elements.sort(MCItem.getComparator(workspace, elements)); // sort custom elements
		elements.addAll(DataListLoader.loadDataList("blocksitems").stream().map(e -> (MCItem) e).toList());
		return elements.stream().filter(typeMatches("block", "item", "tag"))
				.filter(e -> e.isSupportedInWorkspace(workspace)).collect(Collectors.toList());
	}

	/**
	 * Loads all blocks without those that are wildcard elements to subtypes (wood: oak wood, cherry wood, ...)
	 * so only oak wood, cherry wood, ... are loaded, without wildcard wood element
	 *
	 * @return All Blocks from both Minecraft and custom elements with or without metadata
	 */
	public static List<MCItem> loadBlocks(Workspace workspace) {
		List<MCItem> elements = new ArrayList<>();
		workspace.getModElements().forEach(modElement -> elements.addAll(modElement.getMCItems()));
		elements.sort(MCItem.getComparator(workspace, elements)); // sort custom elements
		elements.addAll(
				DataListLoader.loadDataList("blocksitems").stream().map(e -> (MCItem) e).filter(MCItem::hasNoSubtypes)
						.toList());
		return elements.stream().filter(typeMatches("block", "block_without_item"))
				.filter(e -> e.isSupportedInWorkspace(workspace)).collect(Collectors.toList());
	}

	/**
	 * Loads all mod elements and all Minecraft blocks, including those that
	 * are wildcard elements to subtypes (wood: oak wood, cherry wood, ...)
	 *
	 * @return All Blocks from both Minecraft and custom elements with or without metadata
	 */
	public static List<MCItem> loadBlocksAndTags(Workspace workspace) {
		List<MCItem> elements = new ArrayList<>();
		workspace.getModElements().forEach(modElement -> elements.addAll(modElement.getMCItems()));
		elements.sort(MCItem.getComparator(workspace, elements)); // sort custom elements
		elements.addAll(DataListLoader.loadDataList("blocksitems").stream().map(e -> (MCItem) e).toList());
		return elements.stream().filter(typeMatches("block", "block_without_item", "tag"))
				.filter(e -> e.isSupportedInWorkspace(workspace)).collect(Collectors.toList());
	}

	/**
	 * Loads all items (also blocks if they have item representation), including those
	 * that are wildcard elements to subtypes (wood: oak wood, cherry wood, ...)
	 * This list also provides potions from both Minecraft elements and mod elements.
	 * This will not load blocks without item representation (example fire, water, ...).
	 *
	 * @return All Blocks and Items and Potions from both Minecraft and custom elements with or without metadata
	 */
	public static List<MCItem> loadBlocksAndItemsAndTagsAndPotions(Workspace workspace) {
		List<MCItem> elements = loadBlocksAndItemsAndTags(workspace);
		loadAllPotions(workspace).forEach(potion -> elements.add(new MCItem.Potion(workspace, potion)));
		return elements;
	}

	/**
	 * Loads all items (also blocks if they have item representation), without those
	 * that are wildcard elements to subtypes (wood: oak wood, cherry wood, ...)
	 * so only oak wood, cherry wood, ... are loaded, without wildcard wood element
	 * This list also provides potions from both Minecraft elements and mod elements.
	 * This will not load blocks without item representation (example fire, water, ...).
	 *
	 * @return All Blocks and Items and Potions from both Minecraft and custom elements with or without metadata
	 */
	public static List<MCItem> loadBlocksAndItemsAndPotions(Workspace workspace) {
		List<MCItem> elements = loadBlocksAndItems(workspace);
		loadAllPotions(workspace).forEach(potion -> elements.add(new MCItem.Potion(workspace, potion)));
		return elements;
	}

	public static List<DataListEntry> loadAllAchievements(Workspace workspace) {
		return loadDataListAndElements(workspace, "achievements", null, "achievement");
	}

	public static List<DataListEntry> loadAllTabs(Workspace workspace) {
		return loadDataListAndElements(workspace, "tabs", null, "tab");
	}

	public static List<DataListEntry> loadAllBiomes(Workspace workspace) {
		List<DataListEntry> biomes = getCustomElementsOfType(workspace, ModElementType.BIOME);
		biomes.addAll(DataListLoader.loadDataList("biomes"));
		biomes.sort(DataListEntry.getComparator(workspace, biomes));
		return biomes;
	}

	public static List<DataListEntry> loadAllEnchantments(Workspace workspace) {
		return loadDataListAndElements(workspace, "enchantments", null, "enchantment");
	}

	public static List<DataListEntry> loadAllStructures(Workspace workspace) {
		return loadDataListAndElements(workspace, "structures", null, "structure");
	}

	public static List<DataListEntry> loadMapColors() {
		return DataListLoader.loadDataList("mapcolors");
	}

	public static List<DataListEntry> loadNoteBlockInstruments() {
		return DataListLoader.loadDataList("noteblockinstruments");
	}

	public static List<DataListEntry> loadAnimations(Workspace workspace) {
		List<DataListEntry> animations = new ArrayList<>();
		for (Animation animation : Animation.getAnimations(workspace)) {
			for (String subanimation : animation.getSubanimations()) {
				animations.add(
						new DataListEntry.Dummy(NameMapper.MCREATOR_PREFIX + animation.getName() + "." + subanimation));
			}
		}
		animations.addAll(DataListLoader.loadDataList("animations"));
		animations.sort(DataListEntry.getComparator(workspace, animations));
		return animations;
	}

	public static List<DataListEntry> loadAllEntities(Workspace workspace) {
		List<DataListEntry> retval = getCustomElements(workspace,
				mu -> mu.getBaseTypesProvided().contains(BaseType.ENTITY));
		retval.addAll(DataListLoader.loadDataList("entities"));
		retval.sort(DataListEntry.getComparator(workspace, retval));
		return retval;
	}

	/**
	 * Returns all the spawnable entities, which include custom living entities and entities marked as "spawnable"
	 * in the data lists
	 *
	 * @param workspace The workspace from which to gather the entities
	 * @return All entities that can be spawned
	 */
	public static List<DataListEntry> loadAllSpawnableEntities(Workspace workspace) {
		List<DataListEntry> retval = getCustomElements(workspace,
				mu -> mu.getBaseTypesProvided().contains(BaseType.ENTITY));
		retval.addAll(DataListLoader.loadDataList("entities").stream().filter(typeMatches("spawnable")).toList());
		retval.sort(DataListEntry.getComparator(workspace, retval));
		return retval;
	}

	public static List<DataListEntry> loadCustomEntities(Workspace workspace) {
		List<DataListEntry> retval = getCustomElements(workspace,
				mu -> mu.getBaseTypesProvided().contains(BaseType.ENTITY));
		retval.sort(DataListEntry.getComparator(workspace, retval));
		return retval;
	}

	public static List<String> loadEntityDataListFromCustomEntity(Workspace workspace, String entityName,
			Class<? extends PropertyData<?>> type) {
		if (entityName != null) {
			LivingEntity entity = (LivingEntity) workspace.getModElementByName(
					entityName.replace(NameMapper.MCREATOR_PREFIX, "")).getGeneratableElement();
			if (entity != null) {
				return entity.entityDataEntries.stream().filter(e -> e.property().getClass().equals(type))
						.map(e -> e.property().getName()).toList();
			}
		}
		return new ArrayList<>();
	}

	public static List<DataListEntry> loadAllParticles(Workspace workspace) {
		return loadDataListAndElements(workspace, "particles", null, "particle");
	}

	public static List<DataListEntry> loadAllPotionEffects(Workspace workspace) {
		return loadDataListAndElements(workspace, "effects", null, "potioneffect");
	}

	public static List<DataListEntry> loadAllPotions(Workspace workspace) {
		return loadDataListAndElements(workspace, "potions", null, "potion");
	}

	public static List<DataListEntry> loadAllVillagerProfessions(Workspace workspace) {
		return loadDataListAndElements(workspace, "villagerprofessions", null, "villagerprofession");
	}

	public static List<DataListEntry> loadAllAttributes(Workspace workspace) {
		return loadDataListAndElements(workspace, "attributes", null, "attribute");
	}

	/**
	 * Returns list of blocks attached to a POI for this workspace
	 *
	 * @param workspace Workspace to return for
	 * @return List of blocks attached to a POI for this workspace
	 */
	public static List<MItemBlock> loadAllPOIBlocks(Workspace workspace) {
		List<MItemBlock> elements = loadBlocks(workspace).stream().filter(MCItem::isPOI)
				.map(e -> new MItemBlock(workspace, e.getName())).collect(Collectors.toList());

		for (ModElement modElement : workspace.getModElements()) {
			if (modElement.getGeneratableElement() instanceof IPOIProvider poiProvider)
				elements.addAll(poiProvider.poiBlocks());
		}

		return elements;
	}

	public static List<DataListEntry> getAllBooleanGameRules(Workspace workspace) {
		List<DataListEntry> retval = getCustomElements(workspace, modelement -> {
			if (modelement.getType() == ModElementType.GAMERULE)
				return VariableTypeLoader.BuiltInTypes.LOGIC.getName().equals(modelement.getMetadata("type"));
			return false;
		});

		retval.addAll(DataListLoader.loadDataList("gamerules").stream()
				.filter(typeMatches(VariableTypeLoader.BuiltInTypes.LOGIC.getName())).toList());
		return retval;
	}

	public static List<DataListEntry> getAllNumberGameRules(Workspace workspace) {
		List<DataListEntry> retval = getCustomElements(workspace, modelement -> {
			if (modelement.getType() == ModElementType.GAMERULE)
				return VariableTypeLoader.BuiltInTypes.NUMBER.getName().equals(modelement.getMetadata("type"));
			return false;
		});

		retval.addAll(DataListLoader.loadDataList("gamerules").stream()
				.filter(typeMatches(VariableTypeLoader.BuiltInTypes.NUMBER.getName())).toList());
		return retval;
	}

	public static List<DataListEntry> loadAllFluids(Workspace workspace) {
		List<DataListEntry> retval = new ArrayList<>();

		for (ModElement modElement : workspace.getModElements()) {
			if (modElement.getType() == ModElementType.FLUID) {
				retval.add(new DataListEntry.Custom(modElement));
				retval.add(new DataListEntry.Custom(modElement, ":Flowing"));
			}
		}

		retval.addAll(DataListLoader.loadDataList("fluids"));

		return retval.stream().filter(e -> e.isSupportedInWorkspace(workspace)).toList();
	}

	public static String[] getAllSounds(Workspace workspace) {
		ArrayList<String> retval = new ArrayList<>();

		for (SoundElement soundElement : workspace.getSoundElements()) {
			retval.add(NameMapper.MCREATOR_PREFIX + soundElement.getName());
		}

		retval.addAll(DataListLoader.loadDataList("sounds").stream()
				.sorted(Comparator.comparing(DataListEntry::getReadableName)).map(DataListEntry::getName).toList());

		return retval.toArray(new String[0]);
	}

	public static List<DataListEntry> loadAllConfiguredFeatures(Workspace workspace) {
		List<DataListEntry> retval = getCustomElements(workspace,
				mu -> mu.getBaseTypesProvided().contains(BaseType.CONFIGUREDFEATURE));
		retval.addAll(DataListLoader.loadDataList("configuredfeatures").stream()
				.filter(e -> e.isSupportedInWorkspace(workspace)).toList());
		return retval;
	}

	public static List<DataListEntry> loadStepSounds() {
		return DataListLoader.loadDataList("stepsounds");
	}

	public static List<DataListEntry> loadArrowProjectiles(Workspace workspace) {
		List<DataListEntry> retval = getCustomElementsOfType(workspace, ModElementType.PROJECTILE);

		retval.addAll(DataListLoader.loadDataList("projectiles").stream().filter(typeMatches("arrow")).toList());
		return retval;
	}

	public static String[] loadDirections() {
		return new String[] { "DOWN", "UP", "NORTH", "SOUTH", "WEST", "EAST" };
	}

	public static ArrayList<String> loadBasicGUIs(Workspace workspace) {
		ArrayList<String> blocks = new ArrayList<>();
		for (ModElement mu : workspace.getModElements()) {
			if (mu.getType() == ModElementType.GUI)
				blocks.add(mu.getName());
		}
		return blocks;
	}

	public static List<DataListEntry> loadAllGameEvents() {
		return DataListLoader.loadDataList("gameevents");
	}

	public static String[] getDataListAsStringArray(String dataList) {
		return DataListLoader.loadDataList(dataList).stream().map(DataListEntry::getName).toArray(String[]::new);
	}

	private static List<DataListEntry> getCustomElements(@Nonnull Workspace workspace,
			Predicate<ModElement> predicate) {
		return workspace.getModElements().stream().filter(predicate).map(DataListEntry.Custom::new)
				.collect(Collectors.toList());
	}

	private static List<DataListEntry> getCustomElementsOfType(@Nonnull Workspace workspace, ModElementType<?> type) {
		return getCustomElements(workspace, modelement -> modelement.getType() == type);
	}

	/**
	 * <p>Returns an array with the names of procedures that return the given variable type</p>
	 *
	 * @param workspace <p>The current workspace</p>
	 * @param type      <p>The {@link VariableType} that the procedures must return</p>
	 * @return <p>An array of strings containing the names of the procedures</p>
	 */
	public static String[] getProceduresOfType(Workspace workspace, VariableType type) {
		return workspace.getModElements().stream().filter(mod -> {
			if (mod.getType() == ModElementType.PROCEDURE) {
				VariableType returnTypeCurrent = mod.getMetadata("return_type") != null ?
						VariableTypeLoader.INSTANCE.fromName((String) mod.getMetadata("return_type")) :
						null;
				return returnTypeCurrent == type;
			}
			return false;
		}).map(ModElement::getName).toArray(String[]::new);
	}
}
