package server.nitro.modules;

import commons.CommonRails;
import commons.color.ColorPalette;

public class MySQLComponent
{
            public database.N21Status.Status dbStatus;
            public String oidColor;
            public String statusMsg;

            public MySQLComponent()
            {
                database.N21AuthConfig.get().ensureMysqlRunning();

                this.dbStatus = database.N21Status.check();

                if (dbStatus.jdbcConnected() && dbStatus.n21DbExists())
                {
                    String host     = database.N21Status.dbHost();

                    int    port     = database.N21Status.dbPort();

                    String locality = (host.equals("localhost") || host.equals("127.0.0.1")) ? "Local" : "Remote";

                    this.oidColor  = ColorPalette.OID_DEFAULT; // COLOR_LIME_GREEN;

                    this.statusMsg = ". MySQL N21 Connected — " + locality + " — Port " + port + " .";
                }
                else if (dbStatus.tcpReachable() || dbStatus.pingable())
                {
                    this.oidColor  = ColorPalette.OID_DEFAULT; //CommonRails.COLOR_TANGERINE;

                    this.statusMsg = ". MySQL Unreachable or Auth Failed — XML Fallback Storage Active .";
                }
                else
                {
                    this.oidColor  = ColorPalette.OID_DEFAULT; //CommonRails.COLOR_STANDARD_RED;

                    this.statusMsg = ". MySQL Not Found or Not Running — XML Fallback Storage Active .";
                }
            }

            public void print(final Object OWNER)
            {
                CommonRails.printSystemComponent(OWNER, OWNER.hashCode(), statusMsg, oidColor);
            }
}