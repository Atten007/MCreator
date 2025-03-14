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

package net.mcreator.ui.minecraft.states;

import net.mcreator.ui.MCreator;
import net.mcreator.ui.component.TechnicalButton;
import net.mcreator.ui.dialogs.StateEditorDialog;
import net.mcreator.ui.init.L10N;
import net.mcreator.ui.init.UIRES;

import javax.swing.*;
import java.awt.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.function.Supplier;
import java.util.stream.Stream;

public class JStateLabel extends JPanel {

	private final MCreator mcreator;
	private final Supplier<List<PropertyData<?>>> properties;
	private final Supplier<Stream<JStateLabel>> otherStates;

	private StateMap stateMap = new StateMap();
	protected boolean allowEmpty = false;
	protected NumberMatchType numberMatchType = NumberMatchType.EQUAL;

	private final JTextField label = new JTextField();
	private final TechnicalButton edit = new TechnicalButton(UIRES.get("16px.edit"));

	public JStateLabel(MCreator mcreator, Supplier<List<PropertyData<?>>> properties,
			Supplier<Stream<JStateLabel>> otherStates) {
		super(new BorderLayout());
		this.mcreator = mcreator;
		this.properties = properties;
		this.otherStates = otherStates;

		label.setDisabledTextColor(label.getForeground());
		label.setBorder(BorderFactory.createCompoundBorder(
				BorderFactory.createMatteBorder(1, 1, 1, 0, UIManager.getColor("Component.borderColor")),
				BorderFactory.createEmptyBorder(0, 5, 0, 5)));
		label.setEnabled(false);
		label.setOpaque(false);

		JScrollPane statePane = new JScrollPane(label);
		statePane.setOpaque(false);
		statePane.getViewport().setOpaque(false);
		statePane.setPreferredSize(new Dimension(300, 30));
		add("Center", statePane);

		edit.setMargin(new Insets(0, 4, 0, 4));
		edit.setToolTipText(L10N.t("components.state_label.edit"));
		edit.addActionListener(e -> editState());

		add("East", edit);

		refreshState();
	}

	@Override public void setEnabled(boolean enabled) {
		super.setEnabled(enabled);
		edit.setEnabled(enabled);
	}

	public boolean editState() {
		List<PropertyData<?>> propertyList = properties.get();
		if (propertyList == null)
			return false;

		StateMap stateMap = StateEditorDialog.open(mcreator, propertyList, getStateMap(), numberMatchType);
		if (stateMap == null)
			return false;

		if (stateMap.isEmpty() && !allowEmpty) {
			JOptionPane.showMessageDialog(mcreator, L10N.t("components.state_label.error_empty"),
					L10N.t("components.state_label.error_empty.title"), JOptionPane.ERROR_MESSAGE);
			return false;
		} else if (otherStates.get().anyMatch(s -> s != this && s.getStateMap().equals(stateMap))) {
			JOptionPane.showMessageDialog(mcreator, L10N.t("components.state_label.error_duplicate"),
					L10N.t("components.state_label.error_duplicate.title"), JOptionPane.ERROR_MESSAGE);
			return false;
		}

		setStateMap(stateMap);
		return true;
	}

	public JStateLabel setAllowEmpty(boolean allowEmpty) {
		this.allowEmpty = allowEmpty;
		return this;
	}

	public JStateLabel setNumberMatchType(NumberMatchType numberMatchType) {
		this.numberMatchType = Objects.requireNonNullElse(numberMatchType, NumberMatchType.EQUAL);
		refreshState();
		return this;
	}

	public StateMap getStateMap() {
		return stateMap;
	}

	public void setStateMap(StateMap stateMap) {
		this.stateMap = stateMap;
		refreshState();
	}

	private void refreshState() {
		List<String> stateParts = new ArrayList<>();
		stateMap.forEach((k, v) -> stateParts.add(renderPropertyValue(k, v)));
		label.setText(L10N.t("components.state_label.when",
				stateParts.isEmpty() ? L10N.t("condition.common.true") : String.join("; ", stateParts)));
	}

	protected String renderPropertyValue(PropertyData<?> property, Object value) {
		String matchSymbol = "=";
		if (property.getClass() == PropertyData.IntegerType.class
				|| property.getClass() == PropertyData.NumberType.class)
			matchSymbol = numberMatchType.getSymbol();
		return property.getName().replace("CUSTOM:", "") + " " + matchSymbol + " " + property.toString(value);
	}

	public enum NumberMatchType {
		LESS("<"), LESS_OR_EQUAL("<="), EQUAL("="), GREATER_OR_EQUAL(">="), GREATER(">");

		private final String symbol;

		NumberMatchType(String symbol) {
			this.symbol = symbol;
		}

		public String getSymbol() {
			return symbol;
		}
	}

}
