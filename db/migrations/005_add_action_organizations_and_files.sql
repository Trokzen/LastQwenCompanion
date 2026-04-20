-- Миграция 005: Таблицы для привязки организаций и файлов к шаблонам действий (actions)
-- Дата: 2026-04-15
-- Описание: Организации и файлы привязываются к шаблонам действий (actions), 
--           а при запуске алгоритма копируются в action_execution_organizations и action_execution_org_files

-- Таблица для связи организаций с шаблонами действий (многие-ко-многим)
CREATE TABLE IF NOT EXISTS action_organizations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_id INTEGER NOT NULL,              -- Ссылка на шаблон действия (actions)
    organization_id INTEGER NOT NULL,        -- Ссылка на организацию
    created_at TEXT DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (action_id) REFERENCES actions(id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    UNIQUE(action_id, organization_id)  -- Уникальность связи
);

-- Таблица для привязки файлов организаций к шаблонам действий
CREATE TABLE IF NOT EXISTS action_org_files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_id INTEGER NOT NULL,              -- Ссылка на шаблон действия (actions)
    organization_id INTEGER NOT NULL,        -- Ссылка на организацию
    reference_file_id INTEGER NOT NULL,      -- Ссылка на файл из organization_reference_files
    created_at TEXT DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (action_id) REFERENCES actions(id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (reference_file_id) REFERENCES organization_reference_files(id) ON DELETE CASCADE,
    UNIQUE(action_id, organization_id, reference_file_id)  -- Уникальность связи
);

-- Индексы для ускорения поиска
CREATE INDEX IF NOT EXISTS idx_action_orgs_action_id ON action_organizations(action_id);
CREATE INDEX IF NOT EXISTS idx_action_orgs_organization_id ON action_organizations(organization_id);
CREATE INDEX IF NOT EXISTS idx_action_org_files_action_id ON action_org_files(action_id);
CREATE INDEX IF NOT EXISTS idx_action_org_files_organization_id ON action_org_files(organization_id);
CREATE INDEX IF NOT EXISTS idx_action_org_files_reference_file_id ON action_org_files(reference_file_id);
