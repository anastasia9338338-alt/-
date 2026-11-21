using System;
using UnityEngine;
using ZooThrow.Data;

namespace ZooThrow.SaveSystem
{
    /// <summary>
    /// JSON save in PlayerPrefs. On WebGL Unity stores PlayerPrefs in the browser's IndexedDB, so progress survives
    /// page reloads without a server. A checksum detects corrupted data; the previous good save is kept as a backup.
    /// </summary>
    public class SaveManager
    {
        const string MainKey = "zoothrow.save.v1";
        const string BackupKey = "zoothrow.save.v1.backup";
        const string HashSuffix = ".hash";

        public enum LoadOutcome { NewGame, Loaded, RestoredBackup, CorruptedReset }

        readonly GameDatabase _db;
        public SaveData Data { get; private set; }
        public LoadOutcome Outcome { get; private set; }
        public bool Dirty { get; private set; }
        public long PreviousSaveUtcTicks { get; private set; }

        public SaveManager(GameDatabase db) { _db = db; }

        public void MarkDirty() => Dirty = true;

        public void Load()
        {
            bool hadMain = PlayerPrefs.HasKey(MainKey);
            var main = TryRead(MainKey);
            if (main != null)
            {
                Data = main;
                Outcome = LoadOutcome.Loaded;
            }
            else
            {
                var backup = TryRead(BackupKey);
                if (backup != null)
                {
                    Data = backup;
                    Outcome = LoadOutcome.RestoredBackup;
                    Debug.LogWarning("[ZooThrow] Основное сохранение повреждено, загружена резервная копия.");
                }
                else
                {
                    Data = SaveData.CreateNew(_db);
                    Outcome = hadMain ? LoadOutcome.CorruptedReset : LoadOutcome.NewGame;
                    if (hadMain) Debug.LogWarning("[ZooThrow] Сохранение повреждено и резервной копии нет — начата новая игра.");
                }
            }
            var fixes = SaveValidator.Sanitize(Data, _db);
            if (fixes.Count > 0 && Outcome != LoadOutcome.NewGame)
                Debug.LogWarning("[ZooThrow] Исправлены поля сохранения: " + string.Join(", ", fixes));
            PreviousSaveUtcTicks = Data.lastSavedUtcTicks;
            Dirty = Outcome != LoadOutcome.Loaded;
        }

        SaveData TryRead(string key)
        {
            if (!PlayerPrefs.HasKey(key)) return null;
            string json = PlayerPrefs.GetString(key, "");
            string hash = PlayerPrefs.GetString(key + HashSuffix, "");
            if (string.IsNullOrEmpty(json) || Hash(json) != hash) return null;
            try
            {
                var data = JsonUtility.FromJson<SaveData>(json);
                return data != null && data.version >= 1 ? data : null;
            }
            catch (Exception e)
            {
                Debug.LogWarning("[ZooThrow] Не удалось разобрать сохранение " + key + ": " + e.Message);
                return null;
            }
        }

        public void Save()
        {
            if (Data == null) return;
            Data.lastSavedUtcTicks = DateTime.UtcNow.Ticks;
            string json = JsonUtility.ToJson(Data);
            // Keep the last good save as a backup before overwriting the main slot.
            if (TryRead(MainKey) != null)
            {
                PlayerPrefs.SetString(BackupKey, PlayerPrefs.GetString(MainKey));
                PlayerPrefs.SetString(BackupKey + HashSuffix, PlayerPrefs.GetString(MainKey + HashSuffix));
            }
            PlayerPrefs.SetString(MainKey, json);
            PlayerPrefs.SetString(MainKey + HashSuffix, Hash(json));
            PlayerPrefs.Save();
            Dirty = false;
        }

        public void DeleteAll()
        {
            PlayerPrefs.DeleteKey(MainKey);
            PlayerPrefs.DeleteKey(MainKey + HashSuffix);
            PlayerPrefs.DeleteKey(BackupKey);
            PlayerPrefs.DeleteKey(BackupKey + HashSuffix);
            PlayerPrefs.Save();
        }

        /// <summary>FNV-1a 64-bit over UTF-16 code units. Detects corruption, not tampering.</summary>
        public static string Hash(string s)
        {
            ulong h = 14695981039346656037UL;
            for (int i = 0; i < s.Length; i++)
            {
                h ^= s[i];
                h *= 1099511628211UL;
            }
            return h.ToString("x16");
        }
    }
}
