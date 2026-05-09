package com.sawitku.service;

import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
@ConditionalOnProperty(name = "app.email.provider", havingValue = "smtp")
@RequiredArgsConstructor
@Slf4j
public class SmtpEmailService implements EmailService {

    private final JavaMailSender mailSender;

    @Value("${app.email.from}")
    private String from;

    @Value("${app.email.reset-url-template}")
    private String resetUrlTemplate;

    @Override
    public void sendPasswordReset(String toEmail, String userName, String resetToken) {
        try {
            String resetUrl = resetUrlTemplate.replace("{token}", resetToken);
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(from);
            helper.setTo(toEmail);
            helper.setSubject("Reset Password Sawitku");
            String html = """
                <html><body style="font-family:Arial,sans-serif;padding:20px;background:#f5f7f4">
                <div style="max-width:600px;margin:0 auto;background:white;padding:30px;border-radius:12px">
                  <h2 style="color:#52B788">Reset Password Sawitku</h2>
                  <p>Halo %s,</p>
                  <p>Klik tombol di bawah untuk reset password Anda:</p>
                  <p style="text-align:center;margin:30px 0">
                    <a href="%s" style="background:#52B788;color:white;padding:12px 24px;text-decoration:none;border-radius:8px;display:inline-block">Reset Password Saya</a>
                  </p>
                  <p>Link berlaku 1 jam. Jika tidak meminta, abaikan email ini.</p>
                  <p style="color:#888;font-size:13px">Atau copy URL: %s</p>
                </div></body></html>
                """.formatted(userName, resetUrl, resetUrl);
            helper.setText(html, true);
            mailSender.send(message);
            log.info("Password reset email sent to {}", toEmail);
        } catch (Exception e) {
            log.error("Failed to send password reset email: {}", e.getMessage());
            throw new RuntimeException("Failed to send email", e);
        }
    }
}
