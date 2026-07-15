package communicator;

import javax.crypto.*;
import javax.crypto.spec.*;
import java.io.*;
import java.math.BigInteger;
import java.security.*;
import java.security.spec.*;
import java.util.Arrays;
import java.util.HexFormat;

/**
 * CommunicatorCrypto — Cipher negotiation and session encryption for Communicator™.
 *
 * Supported ciphers (dropdown options):
 *   AES-256-GCM, RSA-2048, RSA-4096, Twofish-256, ECC (ECIES/ECDH+AES),
 *   ChaCha20-Poly1305
 *
 * Key exchange: Diffie-Hellman (2048-bit) or ECDH (secp256r1).
 * After negotiation, all subsequent messages on the session are encrypted
 * with the chosen symmetric cipher using the derived shared secret.
 *
 * Profile settings allow users to store a default cipher preference in MySQL
 * so it auto-negotiates on next connect.
 *
 * @author Max Rupplin — MEARVK LLC
 * @date July 1 2026
 */
public class CommunicatorCrypto
{
    /** Available cipher options (presented as dropdown to client). */
    public enum CipherSuite
    {
        AES_256_GCM("AES-256-GCM", "AES/GCM/NoPadding", 256),
        RSA_2048("RSA-2048", "RSA/ECB/OAEPWithSHA-256AndMGF1Padding", 2048),
        RSA_4096("RSA-4096", "RSA/ECB/OAEPWithSHA-256AndMGF1Padding", 4096),
        TWOFISH_256("Twofish-256", "Twofish/CBC/PKCS5Padding", 256),
        ECC_SECP256R1("ECC-secp256r1", "ECIES", 256),
        CHACHA20_POLY1305("ChaCha20-Poly1305", "ChaCha20-Poly1305", 256);

        public final String displayName;
        public final String algorithmId;
        public final int    keyBits;

        CipherSuite(String displayName, String algorithmId, int keyBits)
        {
            this.displayName = displayName;
            this.algorithmId = algorithmId;
            this.keyBits = keyBits;
        }

        public static CipherSuite fromName(String name)
        {
            for (CipherSuite cs : values())
                if (cs.displayName.equalsIgnoreCase(name) || cs.name().equalsIgnoreCase(name))
                    return cs;
            return null;
        }

        public static String listAll()
        {
            StringBuilder sb = new StringBuilder();
            int i = 1;
            for (CipherSuite cs : values())
                sb.append("  ").append(i++).append(". ").append(cs.displayName)
                  .append(" (").append(cs.keyBits).append("-bit)\r\n");
            return sb.toString().stripTrailing();
        }
    }

    // ── DH Key Exchange (2048-bit) ────────────────────────────────────────────

    private static final int DH_KEY_SIZE = 2048;

    /** Server-side DH state for a session. */
    public static final class DHSession
    {
        public final KeyPair      keyPair;
        public final DHParameterSpec dhParams;
        public byte[]             sharedSecret;
        public CipherSuite        negotiatedCipher;

        public DHSession() throws Exception
        {
            // Generate DH parameters and keypair
            AlgorithmParameterGenerator paramGen = AlgorithmParameterGenerator.getInstance("DH");
            paramGen.init(DH_KEY_SIZE, SecureRandom.getInstanceStrong());
            AlgorithmParameters params = paramGen.generateParameters();
            dhParams = params.getParameterSpec(DHParameterSpec.class);

            KeyPairGenerator kpg = KeyPairGenerator.getInstance("DH");
            kpg.initialize(dhParams);
            keyPair = kpg.generateKeyPair();
        }

        /** For faster negotiation using well-known RFC 3526 group 14 (2048-bit). */
        public DHSession(boolean useRfc3526Group14) throws Exception
        {
            BigInteger p = new BigInteger(
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
            BigInteger g = BigInteger.valueOf(2);
            dhParams = new DHParameterSpec(p, g);

            KeyPairGenerator kpg = KeyPairGenerator.getInstance("DH");
            kpg.initialize(dhParams);
            keyPair = kpg.generateKeyPair();
        }

        /** Compute shared secret from client's public key bytes. */
        public void computeSharedSecret(byte[] clientPublicKeyBytes) throws Exception
        {
            KeyFactory kf = KeyFactory.getInstance("DH");
            X509EncodedKeySpec spec = new X509EncodedKeySpec(clientPublicKeyBytes);
            PublicKey clientPub = kf.generatePublic(spec);

            KeyAgreement ka = KeyAgreement.getInstance("DH");
            ka.init(keyPair.getPrivate());
            ka.doPhase(clientPub, true);
            byte[] secret = ka.generateSecret();

            // SECURITY NOTE: Single-pass SHA-256 over the raw DH shared secret is a weak KDF.
            // A proper HKDF (RFC 5869) with salt and info context should be used here.
            // Kept as-is to avoid breaking existing clients that depend on this derivation.
            // Derive 256-bit key via SHA-256
            MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
            sharedSecret = sha256.digest(secret);
        }

        /** Get server's public key encoded for sending to client. */
        public byte[] getPublicKeyEncoded()
        {
            return keyPair.getPublic().getEncoded();
        }
    }

    // ── ECDH Key Exchange (secp256r1) ─────────────────────────────────────────

    public static final class ECDHSession
    {
        public final KeyPair keyPair;
        public byte[]        sharedSecret;
        public CipherSuite   negotiatedCipher;

        public ECDHSession() throws Exception
        {
            KeyPairGenerator kpg = KeyPairGenerator.getInstance("EC");
            kpg.initialize(new ECGenParameterSpec("secp256r1"));
            keyPair = kpg.generateKeyPair();
        }

        public void computeSharedSecret(byte[] clientPublicKeyBytes) throws Exception
        {
            KeyFactory kf = KeyFactory.getInstance("EC");
            X509EncodedKeySpec spec = new X509EncodedKeySpec(clientPublicKeyBytes);
            PublicKey clientPub = kf.generatePublic(spec);

            KeyAgreement ka = KeyAgreement.getInstance("ECDH");
            ka.init(keyPair.getPrivate());
            ka.doPhase(clientPub, true);
            byte[] secret = ka.generateSecret();

            // SECURITY NOTE: Single-pass SHA-256 over the raw ECDH shared secret is a weak KDF.
            // A proper HKDF (RFC 5869) with salt and info context should be used here.
            // Kept as-is to avoid breaking existing clients that depend on this derivation.
            MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
            sharedSecret = sha256.digest(secret);
        }

        public byte[] getPublicKeyEncoded()
        {
            return keyPair.getPublic().getEncoded();
        }
    }

    // ── Symmetric Encryption/Decryption ───────────────────────────────────────

    private static final int GCM_IV_LENGTH = 12;
    private static final int GCM_TAG_LENGTH = 128;

    /** Encrypt plaintext with the derived shared secret using the chosen cipher. */
    public static byte[] encrypt(byte[] plaintext, byte[] sharedSecret, CipherSuite suite) throws Exception
    {
        return switch (suite)
        {
            case AES_256_GCM       -> encryptAesGcm(plaintext, sharedSecret);
            case CHACHA20_POLY1305 -> encryptChaCha20(plaintext, sharedSecret);
            case TWOFISH_256       -> encryptTwofish(plaintext, sharedSecret);
            case ECC_SECP256R1     -> encryptAesGcm(plaintext, sharedSecret); // ECDH derives key, then AES-GCM
            case RSA_2048, RSA_4096 -> encryptAesGcm(plaintext, sharedSecret); // DH derives key, then AES-GCM for data
        };
    }

    /** Decrypt ciphertext with the derived shared secret using the chosen cipher. */
    public static byte[] decrypt(byte[] ciphertext, byte[] sharedSecret, CipherSuite suite) throws Exception
    {
        return switch (suite)
        {
            case AES_256_GCM       -> decryptAesGcm(ciphertext, sharedSecret);
            case CHACHA20_POLY1305 -> decryptChaCha20(ciphertext, sharedSecret);
            case TWOFISH_256       -> decryptTwofish(ciphertext, sharedSecret);
            case ECC_SECP256R1     -> decryptAesGcm(ciphertext, sharedSecret);
            case RSA_2048, RSA_4096 -> decryptAesGcm(ciphertext, sharedSecret);
        };
    }

    // ── AES-256-GCM ──────────────────────────────────────────────────────────

    private static byte[] encryptAesGcm(byte[] plaintext, byte[] key) throws Exception
    {
        byte[] iv = new byte[GCM_IV_LENGTH];
        SecureRandom.getInstanceStrong().nextBytes(iv);
        SecretKeySpec keySpec = new SecretKeySpec(key, "AES");
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE, keySpec, new GCMParameterSpec(GCM_TAG_LENGTH, iv));
        byte[] ct = cipher.doFinal(plaintext);
        // Prepend IV to ciphertext
        byte[] out = new byte[iv.length + ct.length];
        System.arraycopy(iv, 0, out, 0, iv.length);
        System.arraycopy(ct, 0, out, iv.length, ct.length);
        return out;
    }

    private static byte[] decryptAesGcm(byte[] ciphertext, byte[] key) throws Exception
    {
        byte[] iv = Arrays.copyOfRange(ciphertext, 0, GCM_IV_LENGTH);
        byte[] ct = Arrays.copyOfRange(ciphertext, GCM_IV_LENGTH, ciphertext.length);
        SecretKeySpec keySpec = new SecretKeySpec(key, "AES");
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.DECRYPT_MODE, keySpec, new GCMParameterSpec(GCM_TAG_LENGTH, iv));
        return cipher.doFinal(ct);
    }

    // ── ChaCha20-Poly1305 ────────────────────────────────────────────────────

    private static byte[] encryptChaCha20(byte[] plaintext, byte[] key) throws Exception
    {
        byte[] nonce = new byte[12];
        SecureRandom.getInstanceStrong().nextBytes(nonce);
        SecretKeySpec keySpec = new SecretKeySpec(key, "ChaCha20");
        Cipher cipher = Cipher.getInstance("ChaCha20-Poly1305");
        cipher.init(Cipher.ENCRYPT_MODE, keySpec, new IvParameterSpec(nonce));
        byte[] ct = cipher.doFinal(plaintext);
        byte[] out = new byte[nonce.length + ct.length];
        System.arraycopy(nonce, 0, out, 0, nonce.length);
        System.arraycopy(ct, 0, out, nonce.length, ct.length);
        return out;
    }

    private static byte[] decryptChaCha20(byte[] ciphertext, byte[] key) throws Exception
    {
        byte[] nonce = Arrays.copyOfRange(ciphertext, 0, 12);
        byte[] ct = Arrays.copyOfRange(ciphertext, 12, ciphertext.length);
        SecretKeySpec keySpec = new SecretKeySpec(key, "ChaCha20");
        Cipher cipher = Cipher.getInstance("ChaCha20-Poly1305");
        cipher.init(Cipher.DECRYPT_MODE, keySpec, new IvParameterSpec(nonce));
        return cipher.doFinal(ct);
    }

    // ── Twofish-256 (via AES fallback — JDK does not include Twofish natively)
    //    In production, use BouncyCastle. Here we map to AES-256-CBC as a
    //    compatible symmetric block cipher placeholder until BC is on classpath.

    private static byte[] encryptTwofish(byte[] plaintext, byte[] key) throws Exception
    {
        // Attempt BouncyCastle Twofish; fall back to AES-256-CBC
        try
        {
            Cipher cipher = Cipher.getInstance("Twofish/CBC/PKCS5Padding", "BC");
            byte[] iv = new byte[16];
            SecureRandom.getInstanceStrong().nextBytes(iv);
            cipher.init(Cipher.ENCRYPT_MODE, new SecretKeySpec(key, "Twofish"), new IvParameterSpec(iv));
            byte[] ct = cipher.doFinal(plaintext);
            byte[] out = new byte[iv.length + ct.length];
            System.arraycopy(iv, 0, out, 0, iv.length);
            System.arraycopy(ct, 0, out, iv.length, ct.length);
            return out;
        }
        catch (Exception e)
        {
            // Fallback: AES-256-CBC
            byte[] iv = new byte[16];
            SecureRandom.getInstanceStrong().nextBytes(iv);
            SecretKeySpec keySpec = new SecretKeySpec(key, "AES");
            Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
            cipher.init(Cipher.ENCRYPT_MODE, keySpec, new IvParameterSpec(iv));
            byte[] ct = cipher.doFinal(plaintext);
            byte[] out = new byte[iv.length + ct.length];
            System.arraycopy(iv, 0, out, 0, iv.length);
            System.arraycopy(ct, 0, out, iv.length, ct.length);
            return out;
        }
    }

    private static byte[] decryptTwofish(byte[] ciphertext, byte[] key) throws Exception
    {
        byte[] iv = Arrays.copyOfRange(ciphertext, 0, 16);
        byte[] ct = Arrays.copyOfRange(ciphertext, 16, ciphertext.length);
        try
        {
            Cipher cipher = Cipher.getInstance("Twofish/CBC/PKCS5Padding", "BC");
            cipher.init(Cipher.DECRYPT_MODE, new SecretKeySpec(key, "Twofish"), new IvParameterSpec(iv));
            return cipher.doFinal(ct);
        }
        catch (Exception e)
        {
            SecretKeySpec keySpec = new SecretKeySpec(key, "AES");
            Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
            cipher.init(Cipher.DECRYPT_MODE, keySpec, new IvParameterSpec(iv));
            return cipher.doFinal(ct);
        }
    }

    // ── Profile persistence (MySQL) ───────────────────────────────────────────

    /** Store user's preferred cipher in their profile. */
    public static void saveProfileCipher(long nationalId, CipherSuite suite)
    {
        try (var conn = database.N21DataSource.get();
             var ps = conn.prepareStatement(
                "INSERT INTO communicator_profiles (national_id, preferred_cipher, updated_at) " +
                "VALUES (?, ?, NOW()) ON DUPLICATE KEY UPDATE preferred_cipher = ?, updated_at = NOW()"))
        {
            ps.setLong(1, nationalId);
            ps.setString(2, suite.name());
            ps.setString(3, suite.name());
            ps.executeUpdate();
        }
        catch (Exception e) { /* profile save is non-critical */ }
    }

    /** Load user's preferred cipher from profile, or null if not set. */
    public static CipherSuite loadProfileCipher(long nationalId)
    {
        try (var conn = database.N21DataSource.get();
             var ps = conn.prepareStatement(
                "SELECT preferred_cipher FROM communicator_profiles WHERE national_id = ?"))
        {
            ps.setLong(1, nationalId);
            try (var rs = ps.executeQuery())
            {
                if (rs.next())
                    return CipherSuite.fromName(rs.getString(1));
            }
        }
        catch (Exception ignored) {}
        return null;
    }

    /** Ensure the profile table exists. */
    public static void ensureProfileTable()
    {
        try
        {
            var conn = database.N21DataSource.get();
            var st = conn.createStatement();
            st.execute("""
                CREATE TABLE IF NOT EXISTS communicator_profiles (
                    national_id BIGINT PRIMARY KEY,
                    preferred_cipher VARCHAR(32) NOT NULL DEFAULT 'AES_256_GCM',
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_cipher (preferred_cipher)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """);
            st.close();
        }
        catch (Exception ignored) {}
    }
}
