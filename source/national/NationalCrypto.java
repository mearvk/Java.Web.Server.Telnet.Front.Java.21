package national;

import database.N21Store;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.security.*;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

/**
 * NationalCrypto — automatic crypto dispatch based on usage context.
 *
 * Policy:
 *   AES-256        → file transfer (bulk symmetric encryption)
 *   RSA-2048       → signal / non-chat communication (encrypt + verify)
 *   DSA-2048       → chat / small binary signing (≤ 512 bits payload)
 *
 * All keys are loaded from user_keypairs by national_id.
 */
public class NationalCrypto
{
    public enum Purpose { FILE_TRANSFER, SIGNAL, CHAT }

    // ── AES: file transfer ────────────────────────────────────────────────────

    public static byte[] encryptFile(long nationalId, byte[] data)
    {
        try
        {
            SecretKeySpec key = loadAesKey(nationalId);
            Cipher cipher = Cipher.getInstance("AES/ECB/PKCS5Padding");
            cipher.init(Cipher.ENCRYPT_MODE, key);
            return cipher.doFinal(data);
        }
        catch (Exception e) { throw new RuntimeException("AES encrypt failed", e); }
    }

    public static byte[] decryptFile(long nationalId, byte[] data)
    {
        try
        {
            SecretKeySpec key = loadAesKey(nationalId);
            Cipher cipher = Cipher.getInstance("AES/ECB/PKCS5Padding");
            cipher.init(Cipher.DECRYPT_MODE, key);
            return cipher.doFinal(data);
        }
        catch (Exception e) { throw new RuntimeException("AES decrypt failed", e); }
    }

    // ── RSA: signal ───────────────────────────────────────────────────────────

    public static byte[] encryptSignal(long nationalId, byte[] data)
    {
        try
        {
            PublicKey pub = loadRsaPublic(nationalId);
            Cipher cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding");
            cipher.init(Cipher.ENCRYPT_MODE, pub);
            return cipher.doFinal(data);
        }
        catch (Exception e) { throw new RuntimeException("RSA encrypt failed", e); }
    }

    public static byte[] decryptSignal(long nationalId, byte[] data)
    {
        try
        {
            PrivateKey priv = loadRsaPrivate(nationalId);
            Cipher cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding");
            cipher.init(Cipher.DECRYPT_MODE, priv);
            return cipher.doFinal(data);
        }
        catch (Exception e) { throw new RuntimeException("RSA decrypt failed", e); }
    }

    // ── DSA: chat / small binary signing ──────────────────────────────────────

    public static byte[] signChat(long nationalId, byte[] data)
    {
        try
        {
            PrivateKey priv = loadDsaPrivate(nationalId);
            Signature sig = Signature.getInstance("SHA256withDSA");
            sig.initSign(priv);
            sig.update(data);
            return sig.sign();
        }
        catch (Exception e) { throw new RuntimeException("DSA sign failed", e); }
    }

    public static boolean verifyChat(long nationalId, byte[] data, byte[] signature)
    {
        try
        {
            PublicKey pub = loadDsaPublic(nationalId);
            Signature sig = Signature.getInstance("SHA256withDSA");
            sig.initVerify(pub);
            sig.update(data);
            return sig.verify(signature);
        }
        catch (Exception e) { throw new RuntimeException("DSA verify failed", e); }
    }

    // ── Auto-dispatch ─────────────────────────────────────────────────────────

    /**
     * Automatically selects the correct crypto operation based on purpose.
     * For FILE_TRANSFER: AES encrypt.  For SIGNAL: RSA encrypt.  For CHAT: DSA sign.
     */
    public static byte[] encrypt(long nationalId, byte[] data, Purpose purpose)
    {
        return switch (purpose)
        {
            case FILE_TRANSFER -> encryptFile(nationalId, data);
            case SIGNAL        -> encryptSignal(nationalId, data);
            case CHAT          -> signChat(nationalId, data);
        };
    }

    /**
     * Automatically selects the correct crypto operation based on purpose.
     * For FILE_TRANSFER: AES decrypt.  For SIGNAL: RSA decrypt.  For CHAT: DSA verify (returns null; use verifyChat).
     */
    public static byte[] decrypt(long nationalId, byte[] data, Purpose purpose)
    {
        return switch (purpose)
        {
            case FILE_TRANSFER -> decryptFile(nationalId, data);
            case SIGNAL        -> decryptSignal(nationalId, data);
            case CHAT          -> null; // use verifyChat(nationalId, data, signature) instead
        };
    }

    // ── Key loaders ───────────────────────────────────────────────────────────

    private static SecretKeySpec loadAesKey(long nationalId)
    {
        String[] keys = N21Store.loadKeypair(nationalId, "aes");
        if (keys == null || keys.length == 0) throw new RuntimeException("No AES key for NID " + nationalId);
        return new SecretKeySpec(Base64.getDecoder().decode(keys[0]), "AES");
    }

    private static PublicKey loadRsaPublic(long nationalId) throws Exception
    {
        String[] keys = N21Store.loadKeypair(nationalId, "rsa");
        if (keys == null) throw new RuntimeException("No RSA keys for NID " + nationalId);
        return KeyFactory.getInstance("RSA").generatePublic(new X509EncodedKeySpec(Base64.getDecoder().decode(keys[0])));
    }

    private static PrivateKey loadRsaPrivate(long nationalId) throws Exception
    {
        String[] keys = N21Store.loadKeypair(nationalId, "rsa");
        if (keys == null) throw new RuntimeException("No RSA keys for NID " + nationalId);
        return KeyFactory.getInstance("RSA").generatePrivate(new PKCS8EncodedKeySpec(Base64.getDecoder().decode(keys[1])));
    }

    private static PublicKey loadDsaPublic(long nationalId) throws Exception
    {
        String[] keys = N21Store.loadKeypair(nationalId, "dsa");
        if (keys == null) throw new RuntimeException("No DSA keys for NID " + nationalId);
        return KeyFactory.getInstance("DSA").generatePublic(new X509EncodedKeySpec(Base64.getDecoder().decode(keys[0])));
    }

    private static PrivateKey loadDsaPrivate(long nationalId) throws Exception
    {
        String[] keys = N21Store.loadKeypair(nationalId, "dsa");
        if (keys == null) throw new RuntimeException("No DSA keys for NID " + nationalId);
        return KeyFactory.getInstance("DSA").generatePrivate(new PKCS8EncodedKeySpec(Base64.getDecoder().decode(keys[1])));
    }
}
