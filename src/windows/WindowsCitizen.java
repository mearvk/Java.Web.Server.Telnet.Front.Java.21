package windows;

/** Non-secret identity and accountability context attached to an operation. */
public record WindowsCitizen(String id, String displayName) {
    public WindowsCitizen {
        if (id == null || id.isBlank()) throw new IllegalArgumentException("id is required");
        if (displayName == null || displayName.isBlank()) throw new IllegalArgumentException("displayName is required");
    }
}
