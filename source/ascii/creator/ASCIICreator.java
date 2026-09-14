package ascii.creator;

public class ASCIICreator
{
    private static final int SIZE = 5;
    private static final int TOTAL_BITS = 21; // $2^21 = 2,097,152$ unique combinations

    public static void main(String[] args) {
        int[] exampleIds = {0, 1048576, 2097151};

        for (int id : exampleIds) {
            System.out.println("--- ASCII Scan Code for ID: " + id + " ---");
            String asciiGrid = generateAsciiCode(id);
            System.out.println(asciiGrid);
        }
    }

    /**
     * Converts a unique ID into a 5x5 ASCII scan code grid.
     * @param id An integer between 0 and 2,097,151
     * @return A string representing the 2D ASCII art code
     */
    public static String generateAsciiCode(int id) {
        if (id < 0 || id >= (1 << TOTAL_BITS)) {
            throw new IllegalArgumentException("ID must be between 0 and " + ((1 << TOTAL_BITS) - 1));
        }

        char[][] grid = new char[SIZE][SIZE];
        int bitIndex = 0;

        for (int r = 0; r < SIZE; r++) {
            for (int c = 0; c < SIZE; c++) {
                if (r == 0 && c == 0) {
                    grid[r][c] = '█'; // Top-left anchor
                } else if ((r == 0 && c == SIZE - 1) ||
                        (r == SIZE - 1 && c == 0) ||
                        (r == SIZE - 1 && c == SIZE - 1)) {
                    grid[r][c] = ' ';
                }
                else {
                    int bit = (id >> bitIndex) & 1;
                    grid[r][c] = (bit == 1) ? '█' : ' ';
                    bitIndex++;
                }
            }
        }

        StringBuilder sb = new StringBuilder();
        sb.append("┌──────────┐\n");
        for (int r = 0; r < SIZE; r++) {
            sb.append("│ ");
            for (int c = 0; c < SIZE; c++) {
                sb.append(grid[r][c]).append(grid[r][c]);
            }
            sb.append(" │\n");
        }
        sb.append("└──────────┘");
        return sb.toString();
    }
}
