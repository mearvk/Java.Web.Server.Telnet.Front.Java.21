package red.Futures.source.ai.server;

import java.security.*;
import java.security.spec.*;
import javax.crypto.*;
import javax.crypto.spec.*;
import java.math.BigInteger;
import java.util.Base64;

/**
 * EncryptionService — RSA-2048+ key generation and Diffie-Hellman key exchange.
 *
 * Capabilities:
 * - RSA-2048 / RSA-4096 keypair generation
 * - RSA encryption/decryption (OAEP padding)
 * - Diffie-Hellman key exchange (2048-bit)
 * - DH shared secret derivation
 *
 * Awareness (trade issues, skill requirements, renewal, risks):
 * - RSA keys MUST be renewed every 2 years (NIST SP 800-57)
 * - DH is vulnerable to man-in-the-middle without authentication
 * - DH small-subgroup attacks require safe prime validation
 * - Export regulations: RSA >1024-bit restricted under Wassenaar Arrangement
 * - EAR (Export Administration Regulations) apply to strong crypto distribution
 * - Skill: DH parameter generation requires understanding of group theory
 * - Social risk: DH without forward secrecy exposes all past sessions if compromised
 * - Renewal: DH ephemeral keys should be single-use; static DH is deprecated
 *
 * @author MEARVK LLC — Max Rupplin
 * @date June 2026
 */
public class EncryptionService
{
    // ── RSA ───────────────────────────────────────────────────────────────────

    public KeyPair generateRSA(int bits) throws NoSuchAlgorithmException
    {
        if (bits < 2048) throw new IllegalArgumentException("Minimum RSA-2048 required");
        KeyPairGenerator gen = KeyPairGenerator.getInstance("RSA");
        gen.initialize(bits, SecureRandom.getInstanceStrong());
        return gen.generateKeyPair();
    }

    public byte[] encryptRSA(PublicKey pub, byte[] plaintext) throws Exception
    {
        Cipher cipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
        cipher.init(Cipher.ENCRYPT_MODE, pub);
        return cipher.doFinal(plaintext);
    }

    public byte[] decryptRSA(PrivateKey priv, byte[] ciphertext) throws Exception
    {
        Cipher cipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
        cipher.init(Cipher.DECRYPT_MODE, priv);
        return cipher.doFinal(ciphertext);
    }

    // ── Diffie-Hellman ────────────────────────────────────────────────────────

    public KeyPair generateDH() throws Exception
    {
        // RFC 3526 Group 14 (2048-bit MODP)
        DHParameterSpec dhSpec = new DHParameterSpec(DH_P_2048, DH_G);
        KeyPairGenerator gen = KeyPairGenerator.getInstance("DH");
        gen.initialize(dhSpec);
        return gen.generateKeyPair();
    }

    public byte[] deriveDHSecret(PrivateKey myPrivate, PublicKey theirPublic) throws Exception
    {
        KeyAgreement ka = KeyAgreement.getInstance("DH");
        ka.init(myPrivate);
        ka.doPhase(theirPublic, true);
        return ka.generateSecret();
    }

    // RFC 3526 Group 14: 2048-bit MODP prime
    private static final BigInteger DH_P_2048 = new BigInteger(
        "FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD1" +
        "29024E088A67CC74020BBEA63B139B22514A08798E3404DD" +
        "EF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245" +
        "E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED" +
        "EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3D" +
        "C2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F" +
        "83655D23DCA3AD961C62F356208552BB9ED529077096966D" +
        "670C354E4ABC9804F1746C08CA18217C32905E462E36CE3B" +
        "E39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9" +
        "DE2BCBF6955817183995497CEA956AE515D2261898FA0510" +
        "15728E5A8AACAA68FFFFFFFFFFFFFFFF", 16);
    private static final BigInteger DH_G = BigInteger.TWO;
}
