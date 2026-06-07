/**
 * File-level Javadoc.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */

package messaging;

import commons.CommonRails;
import exceptions.ExceptionHandler;
import encryption.module.aes.two.EncryptionModule;

import java.io.BufferedWriter;
import java.io.OutputStreamWriter;
import java.net.Socket;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Date;
import java.util.Random;

public class MessageOutputHandler implements Runnable
{
    protected String hash = "0xDA717018470E213F";

    protected Socket SOCKET;

    protected StringBuffer BUFFER;

    protected String MESSAGE;


    public MessageOutputHandler(final Socket SOCKET, final StringBuffer BUFFER)
    {
        this.SOCKET = SOCKET;

        this.BUFFER = BUFFER;

        this.MESSAGE = BUFFER == null ? "" : BUFFER.toString();
    }

    public MessageOutputHandler(final Socket SOCKET, final String MESSAGE)
    {
        this.SOCKET = SOCKET;

        this.MESSAGE = MESSAGE;
    }

    @Override
    public void run()
    {
        if(SOCKET!=null && CommonRails.SocketUtils.isSocketConnected(SOCKET))
        {
            try
            {
                BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(SOCKET.getOutputStream()));

                writer.write(BUFFER == null ? "" : BUFFER.toString());

                writer.write(new EncryptionModule(new Random(), "", "").cipher_text);

                writer.flush();
            }
            catch (Exception e)
            {
                ExceptionHandler.dispatch(e);
                if(CommonRails.SocketUtils.isSocketClosed(SOCKET))
                {
                    try
                    {
                        SOCKET.close();
                    }
                    catch (Exception xe)
                    {
                        ExceptionHandler.dispatch(xe);
                        CommonRails.printSystemComponent(this, this.hashCode(),"WebExpress MessageOutputHandler >> closes on try-exception to close ["+SOCKET.toString()+"]");
                    }
                    finally
                    {
                        CommonRails.printSystemComponent(this, this.hashCode(),"WebExpress MessageOutputHandler >> safe closes ["+SOCKET.toString()+"]");
                    }
                }
            }
        }
    }
}
