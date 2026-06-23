package commons.printing;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Marks a method that prints a lifecycle "starts" message.
 * The actual verb used at runtime is resolved from
 * configuration/print-method.xml &lt;starts&gt;&lt;canonical&gt;.
 */
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD, ElementType.CONSTRUCTOR})
public @interface StartsCanonical {}
