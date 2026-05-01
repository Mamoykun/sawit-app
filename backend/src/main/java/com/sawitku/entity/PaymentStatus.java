package com.sawitku.entity;

public enum PaymentStatus {
    /// Awaiting payment from user (Snap token created, not yet paid)
    PENDING,
    /// Successfully captured (settlement or capture status from Midtrans)
    PAID,
    /// Payment denied/failed by gateway or bank
    FAILED,
    /// Snap token expired (default 24h, user didn't complete)
    EXPIRED,
    /// User cancelled the payment flow
    CANCELLED
}
