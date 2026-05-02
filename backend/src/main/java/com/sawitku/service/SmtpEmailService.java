package com.sawitku.service;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

// TODO: To enable SMTP, add spring-boot-starter-mail to pom.xml and set:
//   spring.mail.host, spring.mail.port, spring.mail.username, spring.mail.password
//   app.email.provider=smtp
//
// Then uncomment the implementation below:
//
// import org.springframework.mail.javamail.JavaMailSender;
// import org.springframework.mail.javamail.MimeMessageHelper;
// import jakarta.mail.internet.MimeMessage;

/**
 * SMTP email service — not yet active.
 * Enable with app.email.provider=smtp and wire JavaMailSender.
 */
@Service
@ConditionalOnProperty(name = "app.email.provider", havingValue = "smtp")
public class SmtpEmailService implements EmailService {

    // @Autowired
    // private JavaMailSender mailSender;
    //
    // @Value("${app.email.from}")
    // private String fromAddress;

    @Override
    public void sendPasswordReset(String toEmail, String userName, String resetUrl) {
        // TODO: implement once spring-boot-starter-mail is added to pom.xml
        //
        // try {
        //     MimeMessage message = mailSender.createMimeMessage();
        //     MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
        //     helper.setFrom(fromAddress);
        //     helper.setTo(toEmail);
        //     helper.setSubject("Reset Password - Sawitku");
        //     helper.setText(
        //         "<p>Halo " + userName + ",</p>" +
        //         "<p>Klik link berikut untuk reset password Anda (berlaku 1 jam):</p>" +
        //         "<p><a href=\"" + resetUrl + "\">" + resetUrl + "</a></p>",
        //         true
        //     );
        //     mailSender.send(message);
        // } catch (Exception e) {
        //     throw new RuntimeException("Gagal mengirim email reset password", e);
        // }
        throw new UnsupportedOperationException("SmtpEmailService not yet configured");
    }
}
