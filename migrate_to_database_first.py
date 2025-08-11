#!/usr/bin/env python3
"""
Migration script to move Multiple Lists data from SharedPreferences to database-first approach

This script:
1. Finds existing Multiple Lists games that rely on SharedPreferences
2. Creates proper database relationships in game_list_quotas and official_list_members
3. Makes the claiming process work with database-only approach
"""

import sqlite3
import json
import os
from pathlib import Path

def get_database_path():
    """Find the database file"""
    db_names = [
        "efficials_app_development.db",
        "efficials.db", 
        "database.db"
    ]
    
    for db_name in db_names:
        db_path = Path(db_name)
        if db_path.exists():
            return str(db_path)
    
    print("❌ Database file not found!")
    return None

def migrate_to_database_first():
    """Main migration function"""
    print("🔄 Starting migration to database-first Multiple Lists...")
    
    db_path = get_database_path()
    if not db_path:
        return
    
    print(f"📁 Using database: {db_path}")
    
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        # Find all games with method='advanced' (Multiple Lists)
        cursor.execute("""
            SELECT id, sport_id, created_at FROM games 
            WHERE method = 'advanced'
            ORDER BY id ASC
        """)
        advanced_games = cursor.fetchall()
        
        print(f"📊 Found {len(advanced_games)} Multiple Lists games to migrate")
        
        if len(advanced_games) == 0:
            print("ℹ️  No Multiple Lists games found")
            conn.close()
            return
        
        migrated_games = 0
        
        for game in advanced_games:
            game_id = game['id']
            sport_id = game['sport_id']
            
            print(f"\\n🎯 Processing game {game_id} (sport {sport_id})...")
            
            # Check if this game already has database quotas
            cursor.execute("SELECT COUNT(*) as count FROM game_list_quotas WHERE game_id = ?", (game_id,))
            existing_quotas = cursor.fetchone()['count']
            
            if existing_quotas > 0:
                print(f"✅ Game {game_id} already has {existing_quotas} quotas in database - skipping")
                continue
            
            # For migration, we'll create reasonable defaults for games without explicit data
            # Get all official lists for this sport
            cursor.execute("""
                SELECT id, name FROM official_lists 
                WHERE sport_id = ? 
                ORDER BY name ASC
            """, (sport_id,))
            sport_lists = cursor.fetchall()
            
            if not sport_lists:
                print(f"⚠️  No official lists found for sport {sport_id} - skipping")
                continue
            
            # Get officials assigned to this game to infer which lists were used
            cursor.execute("""
                SELECT DISTINCT ga.official_id
                FROM game_assignments ga
                WHERE ga.game_id = ?
            """, (game_id,))
            assigned_officials = cursor.fetchall()
            
            if not assigned_officials:
                print(f"⚠️  No assigned officials found for game {game_id} - skipping")
                continue
            
            assigned_official_ids = [row['official_id'] for row in assigned_officials]
            print(f"👥 Found {len(assigned_official_ids)} assigned officials")
            
            # For each sport list, check if any assigned officials belong to it
            used_lists = []
            
            for sport_list in sport_lists:
                list_id = sport_list['id']
                list_name = sport_list['name']
                
                # Check if any assigned officials are in this list
                cursor.execute("""
                    SELECT COUNT(*) as count
                    FROM official_list_members olm
                    WHERE olm.list_id = ? AND olm.official_id IN ({})
                """.format(','.join(['?'] * len(assigned_official_ids))), 
                [list_id] + assigned_official_ids)
                
                officials_in_list = cursor.fetchone()['count']
                
                if officials_in_list > 0:
                    used_lists.append({
                        'list_id': list_id,
                        'list_name': list_name,
                        'officials_count': officials_in_list
                    })
                    print(f"  📋 List '{list_name}' has {officials_in_list} assigned officials")
            
            if not used_lists:
                print(f"⚠️  No lists found with assigned officials for game {game_id}")
                # Still create a default entry for the first list
                if sport_lists:
                    first_list = sport_lists[0]
                    used_lists = [{
                        'list_id': first_list['id'],
                        'list_name': first_list['name'],
                        'officials_count': len(assigned_official_ids)
                    }]
                    print(f"  🔧 Using default list '{first_list['name']}' for all officials")
            
            # Create game_list_quotas entries for used lists
            for list_info in used_lists:
                list_id = list_info['list_id']
                officials_count = list_info['officials_count']
                
                # Create reasonable quotas based on assigned officials
                min_required = min(officials_count, 1)  # At least 1
                max_allowed = max(officials_count, 3)   # Allow some buffer
                
                cursor.execute("""
                    INSERT OR REPLACE INTO game_list_quotas 
                    (game_id, list_id, minimum_required, maximum_allowed, current_assigned)
                    VALUES (?, ?, ?, ?, ?)
                """, (game_id, list_id, min_required, max_allowed, officials_count))
                
                print(f"  ✅ Created quota: List {list_id} -> min={min_required}, max={max_allowed}, current={officials_count}")
                
                # Ensure all assigned officials are properly in this list
                for official_id in assigned_official_ids:
                    cursor.execute("""
                        INSERT OR IGNORE INTO official_list_members (official_id, list_id)
                        VALUES (?, ?)
                    """, (official_id, list_id))
            
            migrated_games += 1
            print(f"✅ Migrated game {game_id} with {len(used_lists)} list(s)")
        
        # Commit all changes
        conn.commit()
        conn.close()
        
        print(f"\\n🎉 Migration completed!")
        print(f"✅ Migrated games: {migrated_games}")
        print(f"📊 Total games processed: {len(advanced_games)}")
        
        if migrated_games > 0:
            print("\\n🔄 The Multiple Lists system now uses database-first approach!")
            print("✨ Officials should now be able to claim Multiple Lists games successfully!")
            print("\\n📋 What changed:")
            print("  • Multiple Lists data now stored in game_list_quotas table")
            print("  • Officials properly registered in official_list_members table") 
            print("  • No more dependency on SharedPreferences for claiming")
            print("  • Database is now the single source of truth")
        
    except sqlite3.Error as e:
        print(f"❌ Database error: {e}")
    except Exception as e:
        print(f"❌ Fatal error: {e}")

if __name__ == "__main__":
    migrate_to_database_first()