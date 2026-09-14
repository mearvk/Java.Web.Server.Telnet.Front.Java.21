package commons.process;

public record ProcessDescriptor(String command, long pid) {

    public static ProcessDescriptor from(ProcessBuilder pb, Process p) {
        String cmd = (pb != null && pb.command() != null)
                ? String.join(" ", pb.command())
                : "<unknown>";

        long pid = p.pid();

        return new ProcessDescriptor(cmd, pid);
    }

    @Override
    public String toString() {
        return "cmd=\"" + command + "\", pid=" + pid;
    }
}
