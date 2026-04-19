import java.util.LinkedList;
import java.util.Queue;

public class InputQueue
{
    public Queue<Connection> queue = new LinkedList<>();

    public void add(Connection connection)
    {
        this.queue.add(connection);
    }

    public void remove(Connection connection)
    {
        this.queue.remove(connection);
    }

    public Connection peek()
    {
        return this.queue.peek();
    }
}