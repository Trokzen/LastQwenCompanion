#!/usr/bin/env python3
"""
Скрипт для применения миграции 004.
"""

import sqlite3
from pathlib import Path

DB_PATH = "duty_app.db"
MIGRATION_FILE = "db/migrations/004_add_action_execution_org_files.sql"


def main():
    db_path = Path(DB_PATH)
    if not db_path.exists():
        print(f"База данных не найдена: {db_path}")
        return

    print(f"Подключение к базе данных: {db_path}")
    conn = sqlite3.connect(str(db_path))
    
    # Проверяем существует ли таблица
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='action_execution_org_files';")
    if cursor.fetchone():
        print("Таблица 'action_execution_org_files' уже существует.")
    else:
        print("Применение миграции 004...")
        with open(MIGRATION_FILE, 'r', encoding='utf-8') as f:
            sql = f.read()
        
        try:
            conn.executescript(sql)
            conn.commit()
            print("✓ Миграция 004 успешно применена!")
        except sqlite3.Error as e:
            print(f"✗ Ошибка: {e}")
            conn.rollback()
    
    cursor.close()
    conn.close()
    print("Готово!")


if __name__ == "__main__":
    main()
