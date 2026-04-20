-- Миграция 004: Таблица для привязки файлов организаций к конкретным мероприятиям
-- Дата: 2026-04-15
-- Описание: Позволяет для каждого мероприятия выбрать свои организации и свои файлы у этих организаций

CREATE TABLE IF NOT EXISTS action_execution_org_files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_execution_id INTEGER NOT NULL,           -- Ссылка на мероприятие (действие)
    organization_id INTEGER NOT NULL,               -- Ссылка на организацию
    reference_file_id INTEGER NOT NULL,             -- Ссылка на файл из organization_reference_files
    created_at TEXT DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (action_execution_id) REFERENCES action_executions(id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (reference_file_id) REFERENCES organization_reference_files(id) ON DELETE CASCADE,
    UNIQUE(action_execution_id, organization_id, reference_file_id)  -- Уникальность связи
);

-- Индексы для ускорения поиска
CREATE INDEX IF NOT EXISTS idx_ae_org_files_action_execution_id ON action_execution_org_files(action_execution_id);
CREATE INDEX IF NOT EXISTS idx_ae_org_files_organization_id ON action_execution_org_files(organization_id);
CREATE INDEX IF NOT EXISTS idx_ae_org_files_reference_file_id ON action_execution_org_files(reference_file_id);
