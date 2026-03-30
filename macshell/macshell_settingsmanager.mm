/*
 * This file is part of Katvan
 * Copyright (c) 2024 - 2026 Igor Khanin
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
#import "macshell_settingsmanager.h"

#include <QSettings>

#import <AppKit/AppKit.h>

static constexpr QLatin1StringView SETTING_EDITOR_MODE = QLatin1StringView("editor-mode");

KatvanSettingsManager& KatvanSettingsManager::instance()
{
    static KatvanSettingsManager manager;
    return manager;
}

const katvan::EditorSettings& KatvanSettingsManager::editorSettings()
{
    return d_editorSettings;
}

const katvan::typstdriver::TypstCompilerSettings& KatvanSettingsManager::compilerSettings()
{
    return d_compilerSettings;
}

void KatvanSettingsManager::updateEditorSettings(const katvan::EditorSettings& editorSettings)
{
    d_editorSettings = editorSettings;

    QSettings settings;
    settings.setValue(SETTING_EDITOR_MODE, editorSettings.toModeLine());

    [NSApp sendAction:@selector(settingsUpdated:) to:nil from:nil];
}

void KatvanSettingsManager::updateCompilerSettings(const katvan::typstdriver::TypstCompilerSettings& compilerSettings)
{
    d_compilerSettings = compilerSettings;

    QSettings settings;
    d_compilerSettings.save(settings);

    [NSApp sendAction:@selector(settingsUpdated:) to:nil from:nil];
}

void KatvanSettingsManager::reloadSettings()
{
    QSettings settings;

    QString mode = settings.value(SETTING_EDITOR_MODE).toString();
    d_editorSettings = katvan::EditorSettings{ mode, katvan::EditorSettings::ModeSource::SETTINGS };

    d_compilerSettings = katvan::typstdriver::TypstCompilerSettings{ settings };
}
