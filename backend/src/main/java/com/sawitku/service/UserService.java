package com.sawitku.service;

import com.sawitku.dto.request.ChangePasswordRequest;
import com.sawitku.dto.request.UpdateProfileRequest;
import com.sawitku.dto.response.AuthResponse;
import com.sawitku.entity.User;
import com.sawitku.exception.BusinessException;
import com.sawitku.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public AuthResponse.UserInfo getProfile(User user) {
        return toUserInfo(user);
    }

    @Transactional
    public AuthResponse.UserInfo updateProfile(User user, UpdateProfileRequest req) {
        user.setName(req.getName());
        user.setPhone(req.getPhone() != null && !req.getPhone().isBlank() ? req.getPhone() : null);
        userRepository.save(user);
        return toUserInfo(user);
    }

    @Transactional
    public void changePassword(User user, ChangePasswordRequest req) {
        if (!passwordEncoder.matches(req.getCurrentPassword(), user.getPassword()))
            throw new BusinessException("Password saat ini tidak sesuai", "WRONG_PASSWORD");
        user.setPassword(passwordEncoder.encode(req.getNewPassword()));
        userRepository.save(user);
    }

    private AuthResponse.UserInfo toUserInfo(User user) {
        return AuthResponse.UserInfo.builder()
            .id(user.getId()).name(user.getName())
            .email(user.getEmail()).phone(user.getPhone()).build();
    }
}
