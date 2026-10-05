namespace MultiSocks.Aries.Messages
{
    public class Rrlc : AbstractMessage
    {
        public override string _Name { get => "rrlc"; }

        public override void Process(AbstractAriesServer context, AriesClient client)
        {
            int.TryParse(GetInputCacheValue("SET"), out int set);
            string? body = RoadRuleStore.Experiment("rrlc", set);
            if (body == null)
            {
                client.SendMessage(new RrlcTime());
                return;
            }
            CustomLogger.LoggerAccessor.LogInfo($"[RoadRules] rrlc SET={set} -> '{body}'");
            client.SendMessage(new RawBodyMessage("rrlc", body));
        }
    }
}
