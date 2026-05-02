package com.sawitku.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

/**
 * Development email service — logs the email to the console instead of sending it.
 * Active when app.email.provider=log (the default).
 * Copy the reset URL from the log to test the flow manually.
 */
@Service
@ConditionalOnProperty(name = "app.email.provider", havingValue = "log", matchIfMissing = true)
public class LogEmailService implements EmailService {

    private static final Logger log = LoggerFactory.getLogger(LogEmailService.class);

    @Override
    public void sendPasswordReset(String toEmail, String userName, String resetUrl) {
        log.info("=== [DEV] PASSWORD RESET EMAIL ===");
        log.info("  To      : {}", toEmail);
        log.info("  Name    : {}", userName);
        log.info("  ResetURL: {}", resetUrl);
        log.info("===================================");
    }
}
