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

package net.mcreator.ui.dialogs.tools;

import net.mcreator.element.GeneratableElement;
import net.mcreator.minecraft.TagType;
import net.mcreator.workspace.Workspace;
import net.mcreator.workspace.elements.FolderElement;
import net.mcreator.workspace.elements.TagElement;

import java.util.ArrayList;

public class PackMakerToolUtils {

	public static boolean checkIfNamesAvailable(Workspace workspace, String... names) {
		for (String name : names) {
			if (workspace.containsModElement(name)) {
				return false;
			}
		}

		return true;
	}

	public static void addGeneratableElementToWorkspace(Workspace workspace, FolderElement folder,
			GeneratableElement generatableElement) {
		if (!workspace.containsModElement(generatableElement.getModElement().getName())) {
			generatableElement.getModElement().setParentFolder(folder);
			workspace.getModElementManager().storeModElementPicture(generatableElement);
			workspace.getWorkspace().addModElement(generatableElement.getModElement());
			workspace.getGenerator().generateElement(generatableElement);
			workspace.getModElementManager().storeModElement(generatableElement);
		}
	}

	public static void addTagEntries(Workspace workspace, TagType tagType, String tagName, String... entries) {
		// Create tag if it doesn't exist yet
		TagElement tag = new TagElement(tagType, tagName);
		if (!workspace.getTagElements().containsKey(tag)) {
			workspace.addTagElement(tag);
		}

		// Add entries if they're not already contained in the tag (in normal or managed form)
		ArrayList<String> tagEntries = workspace.getTagElements().get(tag);
		for (String entry : entries) {
			if (!tagEntries.contains(entry) && !tagEntries.contains(TagElement.makeEntryManaged(entry))) {
				tagEntries.add(entry);
			}
		}
	}

}
