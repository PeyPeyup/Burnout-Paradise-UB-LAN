using MultiServerLibrary;
using MultiSocks.Aries.DataStore;
using MultiSocks.Aries.Messages.AccountService.ErrorCodes;
using MultiSocks.Utils;

namespace MultiSocks.Aries.Messages.AccountService
{
    public class Auth : AbstractMessage
    {
        public override string _Name { get => "auth"; }

        public override void Process(AbstractAriesServer context, AriesClient client)
        {
            if (context is not MatchmakerServer mc) return;

            string VERS = GetInputCacheValue("VERS") ?? string.Empty;
            string SKU = GetInputCacheValue("SKU") ?? string.Empty;
            string? MADDR = GetInputCacheValue("MADDR");
            string? NAME = GetInputCacheValue("NAME");
            string? PASS = GetInputCacheValue("PASS");
            string? MAC = GetInputCacheValue("MAC");
            string? LOC = GetInputCacheValue("LOC");
            string? TOKEN = GetInputCacheValue("TOKEN");

            client.VERS = VERS;
            client.SKU = SKU;

            if ((MultiServerLibraryConfiguration.BannedIPs != null && MultiServerLibraryConfiguration.BannedIPs.Contains(client.ADDR))
                || (MultiServerLibraryConfiguration.VpnCheck != null && MultiServerLibraryConfiguration.VpnCheck.IsVpnOrProxy(client.ADDR)))
            {
                client.SendMessage(new AuthBlak());
                return;
            }

            if (SKU == "PS3")
            {
                string[]? maddrparams = MADDR?.Split('$');

                if (maddrparams != null)
                    NAME = maddrparams.FirstOrDefault();
            }

            if (MultiSocksServerConfiguration.PrivatePairMode &&
                context.Project == "BURNOUT5" && SKU == "PC" &&
                MultiSocksServerConfiguration.PrivateMaxUsers > 0 &&
                mc.Users.GetAll().Count(u => u.Username != "brobot24") >= MultiSocksServerConfiguration.PrivateMaxUsers)
            {
                client.SendMessage(new AuthLogn());
                return;
            }

            if (!string.IsNullOrEmpty(NAME))
            {
                if (NAME.Contains("@"))
                    NAME = NAME.Split("@")[0] + NAME.Split("@")[1];

                DbAccount? user = Program.DirtySocksDatabase?.GetByName(NAME);
                if (user == null && MultiSocksServerConfiguration.PrivatePairMode &&
                    context.Project == "BURNOUT5" && SKU == "PC" && !string.IsNullOrEmpty(PASS))
                {
                    string? localPassword = PasswordUtils.Ssc2Decode(PASS, client.SKEY);
                    if (localPassword != null)
                    {
                        Program.DirtySocksDatabase?.CreateNew(new DbAccount
                        {
                            Username = NAME,
                            Password = localPassword,
                            TOS = "1",
                            SHARE = "0",
                            MAIL = "local@burnout.invalid"
                        });
                        user = Program.DirtySocksDatabase?.GetByName(NAME);
                    }
                }
                if (user != null)
                {
                    mc.TryLogin(user, client, PASS, LOC ?? "enUS", MAC, TOKEN);
                    return;
                }
            }
            else if (!string.IsNullOrEmpty(TOKEN))
            {
                mc.TryGuestLogin(client, PASS, LOC ?? "enUS", MAC, TOKEN);
                return;
            }

            client.SendMessage(new AuthImst());
        }
    }
}
