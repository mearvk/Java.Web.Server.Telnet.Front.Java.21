package modules.Defined.source.protocol;

/**
 * FTPDataHandler — Protocol handler for FTP Data Transfer (port 20).
 * Active mode data channel. Monitored for outbound transfers.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date July 2026
 */
public class FTPDataHandler extends ProtocolHandler
{
    public FTPDataHandler()
    {
        super(20, "FTP-DATA", "FTP Data Transfer (active mode)");
    }

    @Override
    public void start()
    {
        active = true;
        logConnection("FTP-DATA handler started (outbound monitoring)");
    }

    @Override
    public void stop()
    {
        active = false;
        logConnection("FTP-DATA handler stopped");
    }
}
