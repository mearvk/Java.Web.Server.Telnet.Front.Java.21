package server.nitro.modules;

import commons.CommonRails;
import commons.color.ColorPalette;

import java.io.FileWriter;
import java.io.PrintWriter;
import java.time.LocalDateTime;

public class MySQLComponent
{
            public database.N21Status.Status dbStatus;
            public String oidColor;
            public String statusMsg;

            public MySQLComponent()
            {
                this.dbStatus = database.N21Status.check();

                if (dbStatus.jdbcConnected() && dbStatus.n21DbExists())
                {
                    String host     = database.N21Status.dbHost();

                    int    port     = database.N21Status.dbPort();

                    String locality = (host.equals("localhost") || host.equals("127.0.0.1")) ? "Local" : "Remote";

                    this.oidColor  = ColorPalette.COLOR_LIME_GREEN;

                    this.statusMsg = ". MYSQL N21 Connected — " + locality + " — Port " + port + " .";
                }
                else if (dbStatus.tcpReachable() || dbStatus.pingable())
                {
                    this.oidColor  = ColorPalette.COLOR_STANDARD_RED;

                    this.statusMsg = ". MySQL Unreachable or Auth Failed — XML Fallback Storage Active .";

                    haltWithException(new RuntimeException("MySQL unreachable or auth failed — TCP reachable but JDBC connection failed"));
                }
                else
                {
                    this.oidColor  = ColorPalette.COLOR_STANDARD_RED;

                    this.statusMsg = ". MySQL Not Found or Not Running — XML Fallback Storage Active .";

                    haltWithException(new RuntimeException("MySQL not found or not running — service unavailable"));
                }
            }

            public void print(final Object OWNER)
            {
                CommonRails.printSystemComponent(OWNER, OWNER.hashCode(), statusMsg, oidColor);
            }

            private void haltWithException(Exception cause)
            {
                CommonRails.printSystemComponent(this, this.hashCode(), statusMsg, oidColor);
                try (PrintWriter pw = new PrintWriter(new FileWriter("exception.log", true)))
                {
                    pw.println("[" + LocalDateTime.now() + "] FATAL — MySQL startup failure");
                    cause.printStackTrace(pw);
                }
                catch (Exception ignored) {}
                System.exit(1);
            }
}