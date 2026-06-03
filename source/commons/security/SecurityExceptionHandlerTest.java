/**
 * Simple runner to test async security exception handling.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */
package commons.security;

public class SecurityExceptionHandlerTest
{
    public static void main(String[] args)
    {
        try
        {
            throw new BodiSecurityException("//bodi/connect - test", Thread.currentThread().getStackTrace()[1]);
        }
        catch (BodiSecurityException e)
        {
            // allow worker to process
            try
            {
                Thread.sleep(500);
            }
            catch (InterruptedException ignored)
            {
            }

            System.out.println("Test completed: exception enqueued.");
        }
    }
}
