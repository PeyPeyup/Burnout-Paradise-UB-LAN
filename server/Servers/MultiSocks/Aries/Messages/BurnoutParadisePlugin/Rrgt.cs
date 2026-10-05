namespace MultiSocks.Aries.Messages
{
    public class Rrgt : AbstractMessage
    {
        public override string _Name { get => "rrgt"; }

        public override void Process(AbstractAriesServer context, AriesClient client)
        {
            int.TryParse(GetInputCacheValue("SET"), out int set);
            string? body = RoadRuleStore.Experiment("rrgt", set);
            if (body == null)
            {
                client.SendMessage(new RrgtTime());
                return;
            }
            CustomLogger.LoggerAccessor.LogInfo($"[RoadRules] rrgt SET={set} R={GetInputCacheValue("R")} -> '{body}'");
            client.SendMessage(new RawBodyMessage("rrgt", body));
        }
    }
}
