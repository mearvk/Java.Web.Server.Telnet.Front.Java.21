package com.mearvk.nsa;
import jakarta.servlet.*; import jakarta.servlet.http.HttpServletResponse; import java.io.IOException;
public class SecurityHeadersFilter implements Filter {
    @Override public void doFilter(ServletRequest req, ServletResponse resp, FilterChain chain) throws IOException, ServletException {
        HttpServletResponse r = (HttpServletResponse) resp;
        r.setHeader("X-Content-Type-Options","nosniff"); r.setHeader("X-Frame-Options","DENY");
        r.setHeader("X-XSS-Protection","1; mode=block"); r.setHeader("Referrer-Policy","strict-origin-when-cross-origin");
        r.setHeader("Permissions-Policy","camera=(), microphone=(), geolocation=()"); chain.doFilter(req,resp);
    }
}
