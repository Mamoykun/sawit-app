package com.sawitku.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

/**
 * Authenticates requests to /api/admin/agent/* via X-Admin-Agent-Key header.
 * If key matches app.agent-api-key, sets a synthetic principal "admin-agent"
 * with ROLE_ADMIN_AGENT — bypassing JWT auth for OpenClaw integration.
 */
@Component
public class AdminAgentKeyFilter extends OncePerRequestFilter {

    @Value("${app.agent-api-key:}")
    private String agentApiKey;

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith("/api/admin/agent/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res,
                                    FilterChain chain) throws ServletException, IOException {
        if (agentApiKey == null || agentApiKey.isBlank()) {
            res.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE, "agent api disabled");
            return;
        }
        String key = req.getHeader("X-Admin-Agent-Key");
        if (key == null || !key.equals(agentApiKey)) {
            res.sendError(HttpServletResponse.SC_UNAUTHORIZED, "invalid agent key");
            return;
        }
        var auth = new UsernamePasswordAuthenticationToken(
            "admin-agent", null,
            List.of(new SimpleGrantedAuthority("ROLE_ADMIN_AGENT"))
        );
        SecurityContextHolder.getContext().setAuthentication(auth);
        chain.doFilter(req, res);
    }
}
