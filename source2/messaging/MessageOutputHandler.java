package messaging;

import commons.CommonRails;
import encryption.AES2;

import java.io.BufferedWriter;
import java.io.OutputStreamWriter;
import java.net.Socket;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Date;

public class MessageOutputHandler implements Runnable
{
    protected String hash = "0xDA717018470E213F";

    protected Socket socket;

    protected StringBuffer buffer;

    protected String message;


    public MessageOutputHandler(Socket socket, StringBuffer buffer)
    {
        this.socket = socket;

        this.buffer = buffer;

        this.message = buffer.toString();
    }

    public MessageOutputHandler(Socket socket, String message)
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

                writer.write(buffer.toString());

                writer.write( new AES2(String.valueOf(this.hashCode() | (this.hashCode() & Date.from(LocalDate.of(1933, 12, 1).atStartOfDay(ZoneId.systemDefault()).toInstant()).hashCode()) | Integer.parseUnsignedInt("1132" ) + Integer.parseInt("11238") /*Nov. 3 28*/ + Integer.parseUnsignedInt("00001238") /*Undersigmed Assignedment a & ANd a Cause*/)).cipher_text );

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
                        CommonRails.printSystemComponent(this.hashCode(),"WebExpress::MessageOutputHandler >> closes on try-exception to close ["+socket.toString()+"]");
                    }
                    finally
                    {
                        CommonRails.printSystemComponent(this.hashCode(),"WebExpress::MessageOutputHandler >> safe closes ["+socket.toString()+"]");
                    }
                }
            }
        }
    }
}
