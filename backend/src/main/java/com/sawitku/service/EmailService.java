package com.sawitku.service;

public interface EmailService {
    /**
     * Send a password reset email.
     *
     * @param toEmail  recipient address
     * @param userName display name of the recipient
     * @param resetUrl full URL including the plaintext reset token
     */
    void sendPasswordReset(String toEmail, String userName, String resetUrl);
}
