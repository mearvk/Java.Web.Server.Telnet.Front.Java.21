package exceptions;


public interface ExceptionListener
{
    int getPriority();

    void onException(ExceptionRecord record);
}