/*
 * MCreator (https://mcreator.net/)
 * Copyright (C) 2012-2020, Pylo
 * Copyright (C) 2020-2023, Pylo, opensource contributors
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

package net.mcreator.element.converter.v2020_4;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import net.mcreator.element.GeneratableElement;
import net.mcreator.element.converter.IConverter;
import net.mcreator.element.parts.EntityEntry;
import net.mcreator.element.types.Biome;
import net.mcreator.workspace.Workspace;

public class BiomeSpawnListConverter implements IConverter {

	@Override
	public GeneratableElement convert(Workspace workspace, GeneratableElement input, JsonElement jsonElementInput) {
		Biome biome = (Biome) input;

		if (jsonElementInput.getAsJsonObject().get("definition").getAsJsonObject().get("spawnList") != null) {
			JsonArray spawnList = jsonElementInput.getAsJsonObject().get("definition").getAsJsonObject()
					.get("spawnList").getAsJsonArray();
			for (JsonElement spawn : spawnList) {
				String name = spawn.getAsJsonObject().get("value").getAsString();

				Biome.SpawnEntry spawnEntry = new Biome.SpawnEntry();
				spawnEntry.entity = new EntityEntry(workspace, name);
				spawnEntry.spawnType = "creature";
				spawnEntry.weight = 15;
				spawnEntry.minGroup = 1;
				spawnEntry.maxGroup = 15;

				biome.spawnEntries.add(spawnEntry);
			}
		}

		return biome;
	}

	@Override public int getVersionConvertingTo() {
		return 10;
	}

}
