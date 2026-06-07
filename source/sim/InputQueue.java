/**
 * File-level Javadoc.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */

package sim;

import connections.Connection;

import java.util.LinkedList;
import java.util.Queue;

public class InputQueue
{
    public Queue<Connection> queue = new LinkedList<>();

    public void add(final Connection CONNECTION)
    {
        this.queue.add(CONNECTION);
    }

    public void remove(final Connection CONNECTION)
    {
        this.queue.remove(CONNECTION);
    }

    public Connection peek()
    {
        return this.queue.peek();
    }
}