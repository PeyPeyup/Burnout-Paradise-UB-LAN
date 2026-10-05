using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Tls;
using Org.BouncyCastle.Tls.Crypto.Impl.BC;
using System.Linq;
using CustomLogger;
using System.Security.Cryptography;

namespace FixedSsl;

public class Ssl3TlsServer : DefaultTlsServer
{
    private readonly Certificate _serverCertificate;
    private readonly AsymmetricKeyParameter _serverPrivateKey;
    private readonly BcTlsCrypto _crypto;

    public Ssl3TlsServer(BcTlsCrypto crypto, Certificate serverCertificate, AsymmetricKeyParameter serverPrivateKey) : base(crypto)
    {
        _crypto = crypto;
        _serverCertificate = serverCertificate;
        _serverPrivateKey = serverPrivateKey;
    }

    public static readonly int[] AESCipherSuites = new int[]
    {
        CipherSuite.TLS_RSA_WITH_AES_128_CBC_SHA,
        CipherSuite.TLS_RSA_WITH_AES_256_CBC_SHA,
    };

    public static readonly int[] RC4CipherSuites = new int[]
    {
        CipherSuite.TLS_RSA_WITH_RC4_128_MD5,
        CipherSuite.TLS_RSA_WITH_RC4_128_SHA
    };

    private static readonly ProtocolVersion[] _supportedVersions = new ProtocolVersion[]
    {
        ProtocolVersion.SSLv3,
        ProtocolVersion.TLSv10,
        ProtocolVersion.TLSv11
    };

    public override ProtocolVersion GetServerVersion()
    {
        LoggerAccessor.LogInfo("[Private Burnout TLS probe] Sending SSL 3 server version");
        return _supportedVersions[0];
    }

    protected override ProtocolVersion[] GetSupportedVersions()
    {
        return _supportedVersions;
    }

    public override byte[] GetNewSessionID()
    {
        // The historical OpenSSL server issues a session identifier even when
        // it does not later resume sessions. Some older clients expect one.
        byte[] sessionId = new byte[32];
        RandomNumberGenerator.Fill(sessionId);
        return sessionId;
    }

    public override int[] GetCipherSuites()
    {
        return AESCipherSuites.Concat(RC4CipherSuites).ToArray();
    }

    protected override int[] GetSupportedCipherSuites()
    {
        return AESCipherSuites.Concat(RC4CipherSuites).ToArray();
    }

    public override void NotifySecureRenegotiation(bool secureRenegotiation)
    {
        if (!secureRenegotiation)
        {
            secureRenegotiation = true;
        }

        base.NotifySecureRenegotiation(secureRenegotiation);
    }

    protected override TlsCredentialedDecryptor GetRsaEncryptionCredentials()
    {
        LoggerAccessor.LogInfo("[Private Burnout TLS probe] Sending generated server certificate");
        return new BcDefaultTlsCredentialedDecryptor(_crypto, _serverCertificate, _serverPrivateKey);
    }

    public override void NotifyAlertReceived(short alertLevel, short alertDescription)
    {
        LoggerAccessor.LogInfo($"[Private Burnout TLS probe] Client alert level={alertLevel}, code={alertDescription}");
        base.NotifyAlertReceived(alertLevel, alertDescription);
    }

    public override void NotifyHandshakeComplete()
    {
        LoggerAccessor.LogInfo("[Private Burnout TLS probe] Handshake complete");
        base.NotifyHandshakeComplete();
    }
}
