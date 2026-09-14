package national;

import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import java.security.*;
import java.util.Base64;

/**
 * Generates a per-user cryptographic keypair bundle (RSA, DSA, AES)
 * at National ID registration time.
 *
 * All keys are stored as Base64-encoded strings for database persistence.
 */
public class NationalKeypairGenerator
{
    public final String rsaPublicKey;
    public final String rsaPrivateKey;
    public final String dsaPublicKey;
    public final String dsaPrivateKey;
    public final String aesKey;

    public NationalKeypairGenerator()
    {
        try
        {
            // RSA 2048-bit
            KeyPairGenerator rsa = KeyPairGenerator.getInstance("RSA");
            rsa.initialize(2048, new SecureRandom());
            KeyPair rsaPair = rsa.generateKeyPair();
            this.rsaPublicKey  = Base64.getEncoder().encodeToString(rsaPair.getPublic().getEncoded());
            this.rsaPrivateKey = Base64.getEncoder().encodeToString(rsaPair.getPrivate().getEncoded());

            // DSA 2048-bit
            KeyPairGenerator dsa = KeyPairGenerator.getInstance("DSA");
            dsa.initialize(2048, new SecureRandom());
            KeyPair dsaPair = dsa.generateKeyPair();
            this.dsaPublicKey  = Base64.getEncoder().encodeToString(dsaPair.getPublic().getEncoded());
            this.dsaPrivateKey = Base64.getEncoder().encodeToString(dsaPair.getPrivate().getEncoded());

            // AES 256-bit
            KeyGenerator aesGen = KeyGenerator.getInstance("AES");
            aesGen.init(256, new SecureRandom());
            SecretKey aesSecret = aesGen.generateKey();
            this.aesKey = Base64.getEncoder().encodeToString(aesSecret.getEncoded());
        }
        catch (Exception e)
        {
            throw new RuntimeException("Keypair generation failed", e);
        }
    }
}
