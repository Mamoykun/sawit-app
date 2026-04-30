package com.sawitku.controller;

import com.sawitku.dto.request.ChangePasswordRequest;
import com.sawitku.dto.request.UpdateProfileRequest;
import com.sawitku.dto.response.ApiResponse;
import com.sawitku.dto.response.AuthResponse;
import com.sawitku.entity.User;
import com.sawitku.service.UserService;
import com.sawitku.util.ResponseUtil;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<AuthResponse.UserInfo>> getProfile(
            @AuthenticationPrincipal User user) {
        return ResponseUtil.ok(userService.getProfile(user));
    }

    @PutMapping("/me")
    public ResponseEntity<ApiResponse<AuthResponse.UserInfo>> updateProfile(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody UpdateProfileRequest req) {
        return ResponseUtil.ok(userService.updateProfile(user, req), "Profil berhasil diperbarui");
    }

    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody ChangePasswordRequest req) {
        userService.changePassword(user, req);
        return ResponseUtil.ok(null, "Password berhasil diubah");
    }
}
