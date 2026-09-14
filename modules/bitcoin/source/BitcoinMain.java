import org.bitcoinj.core.*;
import org.bitcoinj.core.listeners.BlocksDownloadedEventListener;
import org.bitcoinj.core.listeners.ChainDownloadStartedEventListener;
import org.bitcoinj.core.listeners.PeerConnectedEventListener;
import org.bitcoinj.kits.WalletAppKit;
import org.bitcoinj.params.RegTestParams;
import org.bitcoinj.wallet.Wallet;
import org.bitcoinj.wallet.listeners.WalletCoinsReceivedEventListener;

import java.io.File;
import java.net.InetAddress;

public class BitcoinMain
{
    public static void main(String...args) throws Exception
    {
        NetworkParameters params = RegTestParams.get();

        //

        PeerAddress peerAddress = new PeerAddress(params, InetAddress.getByName("mearvk.us"), 18444);

        //

        WalletAppKit walletKit = new WalletAppKit(params, new File("."), "United States");
        walletKit.setPeerNodes(peerAddress);
        walletKit.startAsync();
        walletKit.awaitRunning();

        //

        walletKit.peerGroup().addConnectedEventListener(new PeerConnectedEventListener()
        {
            @Override
            public void onPeerConnected(Peer peer, int peerCount)
            {
                System.out.println("New peer connected: " + peer.getAddress());
                System.out.println("Total peers: " + peerCount);
            }
        });

        walletKit.peerGroup().addBlocksDownloadedEventListener(new BlocksDownloadedEventListener()
        {
            @Override
            public void onBlocksDownloaded(Peer peer, Block block, FilteredBlock filteredBlock, int blocksLeft)
            {
                System.out.println("Blocks left to download: " + blocksLeft);

                if (blocksLeft == 0)
                {
                    System.out.println("Blockchain fully synchronized.");
                }
            }
        });

        walletKit.peerGroup().addChainDownloadStartedEventListener(new ChainDownloadStartedEventListener()
        {
            @Override
            public void onChainDownloadStarted(Peer peer, int blocksLeft)
            {
                System.out.println("Chain download started on peer: " + peer.getAddress());
                System.out.println("Blocks remaining: " + blocksLeft);
            }
        });

        walletKit.wallet().addCoinsReceivedEventListener(new WalletCoinsReceivedEventListener()
        {
            @Override
            public void onCoinsReceived(Wallet wallet, Transaction tx, Coin prevBalance, Coin newBalance)
            {
                System.out.println("Received: " + tx.getValue(wallet));
            }
        });
    }
}
