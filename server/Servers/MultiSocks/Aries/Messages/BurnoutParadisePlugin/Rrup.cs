namespace MultiSocks.Aries.Messages
{
    public class Rrup : AbstractMessage
    {
        public override string _Name { get => "rrup"; }

        public override void Process(AbstractAriesServer context, AriesClient client)
        {
            string? rules = GetInputCacheValue("R");
            string? values = GetInputCacheValue("V");
            string? cars = GetInputCacheValue("C");
            string who = client.User?.Username ?? "unknown";

            if (string.IsNullOrEmpty(rules) || string.IsNullOrEmpty(values))
            {
                client.SendMessage(new RrupTime());
                return;
            }

            string[] r = rules.Split(',');
            string[] v = values.Split(',');
            string[] c = (cars ?? string.Empty).Split(',');
            for (int i = 0; i < r.Length && i < v.Length; i++)
            {
                if (!int.TryParse(r[i], out int rule) || !long.TryParse(v[i], out long value)) continue;
                RoadRuleStore.Add(new RoadRuleRecord
                {
                    User = who,
                    Rule = rule,
                    Value = value,
                    Car = i < c.Length ? c[i] : string.Empty,
                    Utc = DateTime.UtcNow.ToString("o")
                });
            }

            // The game reads VALID as the comma list of rules the server accepted.
            string? experiment = RoadRuleStore.Experiment("rrup", -1);
            client.SendMessage(new RawBodyMessage("rrup", experiment ?? ("VALID=" + rules + "\n")));
        }
    }
}
