/**
 * File-level Javadoc.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */

package messaging;

import commons.CommonRails;
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

    protected Socket socket;

    protected StringBuffer buffer;

    protected String message;


    public MessageOutputHandler(final Socket socket, StringBuffer buffer)
    {
        this.socket = socket;

        this.buffer = buffer;

        this.message = buffer == null ? "" : buffer.toString();
    }

    public MessageOutputHandler(final Socket socket, String message)
    {
        this.socket = socket;

        this.message = message;
    }

    @Override
    public void run()
    {
        if(socket!=null && CommonRails.SocketUtils.isSocketConnected(socket))
        {
            try
            {
                BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream()));

                writer.write(buffer == null ? "" : buffer.toString());

                writer.write(new EncryptionModule(new Random(), "", "").cipher_text);

                writer.flush();
            }
            catch (Exception e)
            {
                if(CommonRails.SocketUtils.isSocketClosed(socket))
                {
                    try
                    {
                        socket.close();
                    }
                    catch (Exception xe)
                    {
                        CommonRails.printSystemComponent(this, this.hashCode(),"WebExpress MessageOutputHandler >> closes on try-exception to close ["+socket.toString()+"]");
                    }
                    finally
                    {
                        CommonRails.printSystemComponent(this, this.hashCode(),"WebExpress MessageOutputHandler >> safe closes ["+socket.toString()+"]");
                    }
                }
            }
        }
    }
}
