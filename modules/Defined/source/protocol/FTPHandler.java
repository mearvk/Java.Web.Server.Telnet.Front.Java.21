package modules.Defined.source.protocol;

/**
 * FTPHandler — Protocol handler for FTP Control (port 21).
 * Supports passive mode and multiple credentials for admins and capitalists.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date July 2026
 */
public class FTPHandler extends ProtocolHandler
{
    private boolean passiveMode = true;

    public FTPHandler()
    {
        super(21, "FTP", "FTP Control — File Transfer Protocol");
    }

    public void setPassiveMode(boolean passive)
    {
        this.passiveMode = passive;
    }

    public boolean isPassiveMode()
    {
        return passiveMode;
    }

    @Override
    public void start()
    {
        active = true;
        logConnection("FTP handler started (passive=" + passiveMode + ")");
    }

    @Override
    public void stop()
    {
        active = false;
        logConnection("FTP handler stopped");
    }
}
