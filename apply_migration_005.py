#!/usr/bin/env python3
"""
Миграция 005: Добавление столбца selected_organizations в таблицу actions
"""

import sqlite3
import os
import sys

def apply_migration():
    # Определяем путь к БД
    db_path = 'duty_app.db'
    
    if not os.path.exists(db_path):
        print(f"База данных {db_path} не найдена.")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Проверяем, есть ли уже столбец selected_organizations
        cursor.execute("PRAGMA table_info(actions)")
        existing_columns = [info[1] for info in cursor.fetchall()]
        
        if 'selected_organizations' not in existing_columns:
            # Добавляем столбец для хранения JSON-массива организаций
            cursor.execute("ALTER TABLE actions ADD COLUMN selected_organizations TEXT;")
            print("Миграция 005: Добавлена колонка selected_organizations в actions.")
        else:
            print("Миграция 005: Колонка selected_organizations уже существует.")
        
        conn.commit()
        conn.close()
        return True
        
    except sqlite3.Error as e:
        print(f"Ошибка при выполнении миграции 005: {e}")
        return False

if __name__ == "__main__":
    success = apply_migration()
    if success:
        print("Миграция 005 успешно применена.")
    else:
        print("Миграция 005 не удалась.")
        sys.exit(1)