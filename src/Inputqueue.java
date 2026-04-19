import java.util.LinkedList;
import java.util.Queue;

public class Inputqueue
{
    public Queue<Connections> queue = new LinkedList<>();

    public void add(Connections connection)
    {
        this.queue.add(connection);
    }

    public void remove(Connections connection)
    {
        this.queue.remove(connection);
    }

    public Connections peek()
    {
        return this.queue.peek();
    }
}