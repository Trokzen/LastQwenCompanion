-- db/init_sqlite_schema.sql
-- Схема базы данных для SQLite, соответствующая PostgreSQL-схеме

-- 1. Создание таблицы пользователей (должностных лиц)
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    login TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    rank TEXT,
    last_name TEXT,
    first_name TEXT,
    middle_name TEXT,
    phone TEXT,
    is_active INTEGER DEFAULT 1,
    is_admin INTEGER DEFAULT 0,
    created_at TEXT DEFAULT (datetime('now', 'localtime')),
    updated_at TEXT DEFAULT (datetime('now', 'localtime'))
);

-- 2. Создание таблицы настроек поста
CREATE TABLE IF NOT EXISTS post_settings (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    workplace_name TEXT,
    post_number TEXT,
    post_name TEXT,
    use_persistent_reminders INTEGER DEFAULT 1,
    sound_enabled INTEGER DEFAULT 1,
    custom_datetime TEXT,
    background_image_path TEXT,
    font_family TEXT DEFAULT 'Arial',
    font_size INTEGER DEFAULT 12,
    background_color TEXT DEFAULT '#ecf0f1',
    current_officer_id INTEGER,
    print_font_family TEXT DEFAULT 'Arial',
    print_font_size INTEGER DEFAULT 12,
    custom_time_label TEXT DEFAULT 'Местное время',
    custom_time_offset_seconds INTEGER DEFAULT 0,
    show_moscow_time INTEGER DEFAULT 1,
    moscow_time_offset_seconds INTEGER DEFAULT 0
);

-- === ТАБЛИЦЫ ДЛЯ АЛГОРИТМОВ ===

CREATE TABLE IF NOT EXISTS algorithms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    time_type TEXT NOT NULL,
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TEXT DEFAULT (datetime('now', 'localtime')),
    updated_at TEXT DEFAULT (datetime('now', 'localtime')),
    CHECK (category IN ('повседневная деятельность', 'боевая готовность', 'противодействие терроризму', 'кризисные ситуации')),
    CHECK (time_type IN ('оперативное', 'астрономическое'))
);

-- Таблица для хранения действий внутри алгоритмов
CREATE TABLE IF NOT EXISTS actions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    algorithm_id INTEGER NOT NULL,
    description TEXT NOT NULL,
    technical_text TEXT,
    start_offset TEXT,
    end_offset TEXT,
    contact_phones TEXT,
    report_materials TEXT,
    selected_organizations TEXT,
    created_at TEXT DEFAULT (datetime('now', 'localtime')),
    updated_at TEXT DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (algorithm_id) REFERENCES algorithms(id) ON DELETE CASCADE
);

-- === НОВЫЕ ТАБЛИЦЫ ДЛЯ СВЯЗИ ОРГАНИЗАЦИЙ И ФАЙЛОВ С ШАБЛОНАМИ ДЕЙСТВИЙ ===

-- Таблица для связи организаций с шаблонами действий (многие-ко-многим)
CREATE TABLE IF NOT EXISTS action_template_organizations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_id INTEGER NOT NULL,
    organization_id INTEGER NOT NULL,
    created_at TEXT DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (action_id) REFERENCES actions(id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    UNIQUE(action_id, organization_id)
);

-- Таблица для привязки файлов организаций к конкретным шаблонам действий
CREATE TABLE IF NOT EXISTS action_template_org_files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_id INTEGER NOT NULL,
    organization_id INTEGER NOT NULL,
    reference_file_id INTEGER NOT NULL,
    created_at TEXT DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (action_id) REFERENCES actions(id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (reference_file_id) REFERENCES organization_reference_files(id) ON DELETE CASCADE,
    UNIQUE(action_id, organization_id, reference_file_id)
);

-- Таблица для хранения запущенных экземпляров алгоритмов
CREATE TABLE IF NOT EXISTS algorithm_executions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    algorithm_id INTEGER,
    snapshot_name TEXT NOT NULL,
    snapshot_category TEXT NOT NULL,
    snapshot_time_type TEXT NOT NULL,
    snapshot_description TEXT,
    started_at TEXT,
    completed_at TEXT,
    status TEXT DEFAULT 'active',
    created_by_user_id INTEGER,
    created_by_user_display_name TEXT,
    created_at TEXT DEFAULT (datetime('now', 'localtime')),
    updated_at TEXT DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (algorithm_id) REFERENCES algorithms(id) ON DELETE CASCADE,
    CHECK (status IN ('active', 'completed', 'cancelled'))
);

-- Таблица для хранения выполнения действий в рамках запущенного алгоритма
CREATE TABLE IF NOT EXISTS action_executions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    execution_id INTEGER NOT NULL,
    snapshot_description TEXT NOT NULL,
    snapshot_technical_text TEXT,
    snapshot_contact_phones TEXT,
    snapshot_report_materials TEXT,
    calculated_start_time TEXT,
    calculated_end_time TEXT,
    actual_end_time TEXT,
    status TEXT DEFAULT 'pending',
    reported_to TEXT,
    notes TEXT,
    created_at TEXT DEFAULT (datetime('now', 'localtime')),
    updated_at TEXT DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (execution_id) REFERENCES algorithm_executions(id) ON DELETE CASCADE,
    CHECK (status IN ('pending', 'in_progress', 'completed', 'skipped'))
);

-- === ИНДЕКСЫ ===

CREATE INDEX IF NOT EXISTS idx_actions_algorithm_id ON actions(algorithm_id);
CREATE INDEX IF NOT EXISTS idx_algorithm_executions_algorithm_id ON algorithm_executions(algorithm_id);
CREATE INDEX IF NOT EXISTS idx_algorithm_executions_status ON algorithm_executions(status);
CREATE INDEX IF NOT EXISTS idx_action_executions_execution_id ON action_executions(execution_id);
CREATE INDEX IF NOT EXISTS idx_action_executions_status ON action_executions(status);
CREATE INDEX IF NOT EXISTS idx_algorithms_sort_order ON algorithms(sort_order);

-- Индексы для новых таблиц
CREATE INDEX IF NOT EXISTS idx_action_template_orgs_action_id ON action_template_organizations(action_id);
CREATE INDEX IF NOT EXISTS idx_action_template_orgs_org_id ON action_template_organizations(organization_id);
CREATE INDEX IF NOT EXISTS idx_action_template_org_files_action_id ON action_template_org_files(action_id);
CREATE INDEX IF NOT EXISTS idx_action_template_org_files_org_id ON action_template_org_files(organization_id);
CREATE INDEX IF NOT EXISTS idx_action_template_org_files_file_id ON action_template_org_files(reference_file_id);

-- === НАЧАЛЬНЫЕ ДАННЫЕ ===

INSERT OR IGNORE INTO post_settings (
    id, workplace_name, post_number, post_name,
    print_font_family, print_font_size, custom_time_label,
    custom_time_offset_seconds, show_moscow_time, moscow_time_offset_seconds,
    use_persistent_reminders, sound_enabled
) VALUES (
    1, 'Рабочее место дежурного', '1', 'Дежурство по части',
    'Arial', 12, 'Местное время', 0, 1, 0, 1, 1
);

INSERT OR IGNORE INTO users (
    login, password_hash, rank, last_name, first_name, middle_name, is_admin
) VALUES (
    'admin',
    'scrypt:32768:8:1$Atn4MrMt5x0I1XQr$a9f9efc8c59fdf784156004ace3717466af3e871cc9f4ee6a07ec72dc7319196fd741dde5d3458b21731c92e57fcc833eec0141a746d46237816dc016ef76475',
    'Администратор', 'Админов', 'Админ', 'Админович', 1
);

-- === ТАБЛИЦЫ ДЛЯ МЕРОПРИЯТИЙ ===

CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    recurrence_rule TEXT,
    start_time TEXT,
    end_time TEXT,
    notification_offset TEXT,
    responsible_user_id INTEGER,
    report_materials TEXT,
    created_at TEXT DEFAULT (datetime('now', 'localtime')),
    updated_at TEXT DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (responsible_user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS event_occurrences (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_id INTEGER NOT NULL,
    calculated_start_datetime TEXT,
    calculated_end_datetime TEXT,
    actual_start_datetime TEXT,
    actual_end_datetime TEXT,
    status TEXT DEFAULT 'pending',
    notes TEXT,
    performed_by_user_id INTEGER,
    created_at TEXT DEFAULT (datetime('now', 'localtime')),
    updated_at TEXT DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (event_id) REFERENCES events(id),
    CHECK (status IN ('pending', 'in_progress', 'completed', 'missed', 'cancelled'))
);

CREATE INDEX IF NOT EXISTS idx_events_responsible_user_id ON events(responsible_user_id);
CREATE INDEX IF NOT EXISTS idx_event_occurrences_event_id ON event_occurrences(event_id);
CREATE INDEX IF NOT EXISTS idx_event_occurrences_calculated_start_datetime ON event_occurrences(calculated_start_datetime);
CREATE INDEX IF NOT EXISTS idx_event_occurrences_status ON event_occurrences(status);

-- === ТАБЛИЦЫ ДЛЯ ОРГАНИЗАЦИЙ ===

CREATE TABLE IF NOT EXISTS organizations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    phone TEXT,
    contact_person TEXT,
    notes TEXT,
    created_at TEXT DEFAULT (datetime('now', 'localtime')),
    updated_at TEXT DEFAULT (datetime('now', 'localtime'))
);

-- Таблица для связи организаций с действиями (для запущенных экземпляров)
CREATE TABLE IF NOT EXISTS action_execution_organizations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_execution_id INTEGER NOT NULL,
    organization_id INTEGER NOT NULL,
    created_at TEXT DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (action_execution_id) REFERENCES action_executions(id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE
);

-- Таблица для хранения справочных материалов организаций
CREATE TABLE IF NOT EXISTS organization_reference_files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    organization_id INTEGER NOT NULL,
    file_path TEXT NOT NULL,
    file_type TEXT DEFAULT 'other',
    created_at TEXT DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    CHECK (file_type IN ('word', 'excel', 'pdf', 'image', 'other'))
);

-- Таблица для привязки файлов организаций к мероприятиям (для запущенных экземпляров)
CREATE TABLE IF NOT EXISTS action_execution_org_files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_execution_id INTEGER NOT NULL,
    organization_id INTEGER NOT NULL,
    reference_file_id INTEGER NOT NULL,
    created_at TEXT DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (action_execution_id) REFERENCES action_executions(id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (reference_file_id) REFERENCES organization_reference_files(id) ON DELETE CASCADE,
    UNIQUE(action_execution_id, organization_id, reference_file_id)
);

-- === ИНДЕКСЫ ДЛЯ ОРГАНИЗАЦИЙ ===

CREATE INDEX IF NOT EXISTS idx_ae_orgs_action_execution_id ON action_execution_organizations(action_execution_id);
CREATE INDEX IF NOT EXISTS idx_ae_orgs_organization_id ON action_execution_organizations(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_ref_files_organization_id ON organization_reference_files(organization_id);
CREATE INDEX IF NOT EXISTS idx_ae_org_files_action_execution_id ON action_execution_org_files(action_execution_id);
CREATE INDEX IF NOT EXISTS idx_ae_org_files_organization_id ON action_execution_org_files(organization_id);
CREATE INDEX IF NOT EXISTS idx_ae_org_files_reference_file_id ON action_execution_org_files(reference_file_id);
