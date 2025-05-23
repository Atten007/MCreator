/*
 * MCreator (https://mcreator.net/)
 * Copyright (C) 2020 Pylo and contributors
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

package net.mcreator.ui.modgui;

import net.mcreator.blockly.data.Dependency;
import net.mcreator.element.types.GUI;
import net.mcreator.ui.MCreator;
import net.mcreator.ui.MCreatorApplication;
import net.mcreator.ui.component.CollapsiblePanel;
import net.mcreator.ui.component.util.PanelUtils;
import net.mcreator.ui.init.L10N;
import net.mcreator.ui.procedure.ProcedureSelector;
import net.mcreator.ui.wysiwyg.WYSIWYGEditor;
import net.mcreator.workspace.elements.ModElement;

import javax.annotation.Nullable;
import javax.swing.*;
import java.awt.*;
import java.net.URI;
import java.net.URISyntaxException;

public class CustomGUIGUI extends ModElementGUI<GUI> {

	private WYSIWYGEditor editor;

	private ProcedureSelector onOpen;
	private ProcedureSelector onTick;
	private ProcedureSelector onClosed;

	public CustomGUIGUI(MCreator mcreator, ModElement modElement, boolean editingMode) {
		super(mcreator, modElement, editingMode);
		this.initGUI();
		super.finalizeGUI();
	}

	@Override protected void initGUI() {
		editor = new WYSIWYGEditor(mcreator, true);

		onOpen = new ProcedureSelector(this.withEntry("gui/gui_opened"), mcreator, L10N.t("elementgui.gui.gui_opened"),
				Dependency.fromString("x:number/y:number/z:number/world:world/entity:entity"));
		onTick = new ProcedureSelector(this.withEntry("gui/gui_open_tick"), mcreator,
				L10N.t("elementgui.gui.gui_open_ticks"),
				Dependency.fromString("x:number/y:number/z:number/world:world/entity:entity"));
		onClosed = new ProcedureSelector(this.withEntry("gui/gui_closed"), mcreator,
				L10N.t("elementgui.gui.gui_closed"),
				Dependency.fromString("x:number/y:number/z:number/world:world/entity:entity"));

		CollapsiblePanel events = new CollapsiblePanel(L10N.t("elementgui.gui.gui_triggers"),
				PanelUtils.join(FlowLayout.LEFT, 1, 1, PanelUtils.gridElements(1, 3, 5, 0, onOpen, onTick, onClosed)));

		JPanel main = new JPanel(new BorderLayout(0, 5));
		main.setOpaque(false);

		main.add("Center", PanelUtils.centerAndSouthElement(editor, events, 0, 2));
		main.add("East", editor.sidebar);

		addPage(main);
	}

	@Override public void reloadDataLists() {
		super.reloadDataLists();

		onOpen.refreshListKeepSelected();
		onTick.refreshListKeepSelected();
		onClosed.refreshListKeepSelected();
	}

	@Override public void openInEditingMode(GUI gui) {
		editor.setOpening(true);

		editor.spa1.setValue(gui.width);
		editor.spa2.setValue(gui.height);
		editor.invOffX.setValue(gui.inventoryOffsetX);
		editor.invOffY.setValue(gui.inventoryOffsetY);
		editor.setComponentList(gui.components);
		editor.renderBgLayer.setSelected(gui.renderBgLayer);
		editor.doesPauseGame.setSelected(gui.doesPauseGame);

		onOpen.setSelectedProcedure(gui.onOpen);
		onTick.setSelectedProcedure(gui.onTick);
		onClosed.setSelectedProcedure(gui.onClosed);

		editor.getGUITypeSelector().setSelectedIndex(gui.type);
		editor.setSlotComponentsEnabled(editor.getGUITypeSelector().getSelectedIndex() == 1);

		editor.sx.setValue(gui.gridSettings.sx);
		editor.sy.setValue(gui.gridSettings.sy);
		editor.ox.setValue(gui.gridSettings.ox);
		editor.oy.setValue(gui.gridSettings.oy);
		editor.snapOnGrid.setSelected(gui.gridSettings.snapOnGrid);
		if (gui.gridSettings.snapOnGrid) {
			editor.editor.showGrid = true;
			editor.editor.repaint();
		}

		editor.setOpening(false);
	}

	@Override public GUI getElementFromGUI() {
		GUI gui = new GUI(modElement);
		gui.type = editor.getGUITypeSelector().getSelectedIndex();
		gui.width = (int) editor.spa1.getValue();
		gui.height = (int) editor.spa2.getValue();
		gui.inventoryOffsetX = (int) editor.invOffX.getValue();
		gui.inventoryOffsetY = (int) editor.invOffY.getValue();
		gui.components = editor.getComponentList();
		gui.renderBgLayer = editor.renderBgLayer.isSelected();
		gui.doesPauseGame = editor.doesPauseGame.isSelected();
		gui.onOpen = onOpen.getSelectedProcedure();
		gui.onTick = onTick.getSelectedProcedure();
		gui.onClosed = onClosed.getSelectedProcedure();

		gui.gridSettings.sx = (int) editor.sx.getValue();
		gui.gridSettings.sy = (int) editor.sy.getValue();
		gui.gridSettings.ox = (int) editor.ox.getValue();
		gui.gridSettings.oy = (int) editor.oy.getValue();
		gui.gridSettings.snapOnGrid = editor.snapOnGrid.isSelected();
		return gui;
	}

	@Override public @Nullable URI contextURL() throws URISyntaxException {
		return new URI(MCreatorApplication.SERVER_DOMAIN + "/wiki/gui-editor");
	}

}
