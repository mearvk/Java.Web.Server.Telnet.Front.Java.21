package encryption.module.dsa;

import commons.CommonRails;

import java.security.*;

/**
 * Minimal DSA signing module for internet-facing data transmission.
 * Generates a 2048-bit DSA key pair on construction; exposes sign/verify.
 */
public class EncryptionModuleDSA
{
    public final PublicKey  PUBLIC_KEY;
    public final PrivateKey PRIVATE_KEY;

    public EncryptionModuleDSA()
    {
        try
        {
            KeyPairGenerator gen = KeyPairGenerator.getInstance("DSA");
            gen.initialize(2048, new SecureRandom());
            KeyPair pair  = gen.generateKeyPair();
            PUBLIC_KEY    = pair.getPublic();
            PRIVATE_KEY   = pair.getPrivate();
            CommonRails.printSystemComponent(this, this.hashCode(), ". 2048-bit key pair generated .");
        }
        catch (Exception e) { throw new RuntimeException(e); }
    }

    public byte[] sign(final byte[] DATA) throws Exception
    {
        Signature sig = Signature.getInstance("SHA256withDSA");
        sig.initSign(PRIVATE_KEY);
        sig.update(DATA);
        return sig.sign();
    }

    public boolean verify(final byte[] DATA, final byte[] SIGNATURE, final PublicKey KEY) throws Exception
    {
        Signature sig = Signature.getInstance("SHA256withDSA");
        sig.initVerify(KEY);
        sig.update(DATA);
        return sig.verify(SIGNATURE);
    }
}
