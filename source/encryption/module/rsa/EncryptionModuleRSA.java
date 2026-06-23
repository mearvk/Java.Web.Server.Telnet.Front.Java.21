package encryption.module.rsa;

import commons.CommonRails;

import javax.crypto.Cipher;
import java.security.*;

/**
 * Minimal RSA encryption module for internet-facing data transmission.
 * Generates a 2048-bit RSA key pair on construction; exposes encrypt/decrypt.
 */
public class EncryptionModuleRSA
{
    public final PublicKey  PUBLIC_KEY;
    public final PrivateKey PRIVATE_KEY;

    public EncryptionModuleRSA()
    {
        try
        {
            KeyPairGenerator gen = KeyPairGenerator.getInstance("RSA");
            gen.initialize(2048, new SecureRandom());
            KeyPair pair  = gen.generateKeyPair();
            PUBLIC_KEY    = pair.getPublic();
            PRIVATE_KEY   = pair.getPrivate();
            CommonRails.printSystemComponent(this, this.hashCode(), ". 2048-bit key pair generated .");
        }
        catch (Exception e) { throw new RuntimeException(e); }
    }

    public byte[] encrypt(final byte[] DATA, final PublicKey KEY) throws Exception
    {
        Cipher c = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
        c.init(Cipher.ENCRYPT_MODE, KEY);
        return c.doFinal(DATA);
    }

    public byte[] decrypt(final byte[] DATA) throws Exception
    {
        Cipher c = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
        c.init(Cipher.DECRYPT_MODE, PRIVATE_KEY);
        return c.doFinal(DATA);
    }
}
