using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace MultiSocks.Aries.Messages
{
    /// <summary>A reply whose body is sent verbatim (the game parses some road-rule replies as plain comma lists).</summary>
    public class RawBodyMessage : AbstractMessage
    {
        private readonly string _name;
        private readonly string _body;

        public RawBodyMessage(string name, string body)
        {
            _name = name;
            _body = body;
        }

        public override string _Name => _name;
        public override string Write() => _body;
    }

    public class RoadRuleRecord
    {
        public string User { get; set; } = string.Empty;
        public int Rule { get; set; }
        public long Value { get; set; }
        public string Car { get; set; } = string.Empty;
        public string Utc { get; set; } = string.Empty;
    }

    /// <summary>Persistent road-rule record store (static/road-rules.json) plus an optional hot-reloaded
    /// experiment file (static/rr-experiment.json) used to tune leaderboard reply layouts while the game runs.</summary>
    public static class RoadRuleStore
    {
        private static readonly object Gate = new();

        private static string StaticDir =>
            Path.GetDirectoryName(MultiSocksServerConfiguration.DirtySocksDatabasePath) ?? Path.Combine(Directory.GetCurrentDirectory(), "static");

        private static string StorePath => Path.Combine(StaticDir, "road-rules.json");
        private static string ExperimentPath => Path.Combine(StaticDir, "rr-experiment.json");

        public static List<RoadRuleRecord> Load()
        {
            lock (Gate)
            {
                try
                {
                    if (File.Exists(StorePath))
                        return JsonConvert.DeserializeObject<List<RoadRuleRecord>>(File.ReadAllText(StorePath)) ?? new();
                }
                catch (Exception ex)
                {
                    CustomLogger.LoggerAccessor.LogError($"[RoadRules] could not read store: {ex.Message}");
                }
                return new();
            }
        }

        public static void Add(RoadRuleRecord rec)
        {
            lock (Gate)
            {
                // The game re-uploads its whole career table (zeros for unset rules) on every sync:
                // keep only the latest non-zero value per player+rule.
                if (rec.Value <= 0) return;
                List<RoadRuleRecord> all = Load();
                all.RemoveAll(r => r.User == rec.User && r.Rule == rec.Rule);
                all.Add(rec);
                Directory.CreateDirectory(StaticDir);
                File.WriteAllText(StorePath, JsonConvert.SerializeObject(all, Formatting.Indented));
            }
        }

        /// <summary>Returns the experiment body for message <paramref name="msg"/> and leaderboard <paramref name="set"/>, or null.</summary>
        public static string? Experiment(string msg, int set)
        {
            lock (Gate)
            {
                try
                {
                    if (!File.Exists(ExperimentPath)) return null;
                    JObject root = JObject.Parse(File.ReadAllText(ExperimentPath));
                    JToken? t = root[msg];
                    if (t is JArray arr) return set >= 0 && set < arr.Count ? arr[set]?.ToString() : null;
                    return t?.ToString();
                }
                catch (Exception ex)
                {
                    CustomLogger.LoggerAccessor.LogError($"[RoadRules] experiment file error: {ex.Message}");
                    return null;
                }
            }
        }
    }
}
