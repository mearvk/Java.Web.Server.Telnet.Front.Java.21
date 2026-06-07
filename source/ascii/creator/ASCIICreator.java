package ascii.creator;

public class ASCIICreator
{

    // 5x5 grid dimensions
    private static final int SIZE = 5;
    private static final int TOTAL_BITS = 21; // $2^21 = 2,097,152$ unique combinations

    public static void main(String[] args) {
        // Example: Generate three distinct codes out of the 2+ million possibilities
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
                // 1. Assign fixed Orientation Anchors to the corners
                if (r == 0 && c == 0) {
                    grid[r][c] = '█'; // Top-left anchor
                } else if ((r == 0 && c == SIZE - 1) ||
                        (r == SIZE - 1 && c == 0) ||
                        (r == SIZE - 1 && c == SIZE - 1)) {
                    grid[r][c] = ' '; // Other corners stay empty to lock orientation
                }
                // 2. Map the unique ID bits into the remaining 21 slots
                else {
                    // Extract the specific bit from the integer ID
                    int bit = (id >> bitIndex) & 1;
                    // Standard terminal text is tall; using two blocks "██" keeps it square
                    grid[r][c] = (bit == 1) ? '█' : ' ';
                    bitIndex++;
                }
            }
        }

        // 3. Render the grid with a clean visual border
        StringBuilder sb = new StringBuilder();
        sb.append("┌──────────┐\n");
        for (int r = 0; r < SIZE; r++) {
            sb.append("│ ");
            for (int c = 0; c < SIZE; c++) {
                // Print character twice to preserve square aspect ratio in terminals
                sb.append(grid[r][c]).append(grid[r][c]);
            }
            sb.append(" │\n");
        }
        sb.append("└──────────┘");
        return sb.toString();
    }
}
