package auth

import (
	"errors"
	// "net/http"

	"github.com/gin-gonic/gin"
	"github.com/TgkCapture/openair/pkg/utils"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}

	resp, err := h.svc.Register(c.Request.Context(), req)
	if err != nil {
		if errors.Is(err, ErrEmailTaken) {
			utils.Conflict(c, "EMAIL_TAKEN", "email already registered")
			return
		}
		utils.InternalError(c)
		return
	}
	utils.Created(c, resp)
}

func (h *Handler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}

	resp, err := h.svc.Login(c.Request.Context(), req)
	if err != nil {
		if errors.Is(err, ErrInvalidCredentials) || errors.Is(err, ErrAccountDisabled) {
			utils.Unauthorized(c, "INVALID_CREDENTIALS", err.Error())
			return
		}
		utils.InternalError(c)
		return
	}
	utils.OK(c, resp)
}

func (h *Handler) RefreshToken(c *gin.Context) {
	var req RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}

	resp, err := h.svc.RefreshToken(c.Request.Context(), req)
	if err != nil {
		utils.Unauthorized(c, "INVALID_TOKEN", "invalid or expired token")
		return
	}
	utils.OK(c, resp)
}

func (h *Handler) Logout(c *gin.Context) {
	userID := c.GetString("user_id")
	if err := h.svc.Logout(c.Request.Context(), userID); err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, gin.H{"message": "logged out successfully"})
}

func (h *Handler) ForgotPassword(c *gin.Context) {
	var req ForgotPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}
	// Always return 200 to prevent email enumeration
	_ = h.svc.ForgotPassword(c.Request.Context(), req)
	utils.OK(c, gin.H{"message": "if that email exists, an OTP has been sent"})
}

func (h *Handler) ResetPassword(c *gin.Context) {
	var req ResetPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}

	if err := h.svc.ResetPassword(c.Request.Context(), req); err != nil {
		if errors.Is(err, ErrInvalidOTP) {
			utils.BadRequest(c, "INVALID_OTP", "invalid or expired OTP")
			return
		}
		utils.InternalError(c)
		return
	}
	utils.OK(c, gin.H{"message": "password reset successfully"})
}

func (h *Handler) GetProfile(c *gin.Context) {
	userID := c.GetString("user_id")
	user, err := h.svc.GetProfile(c.Request.Context(), userID)
	if err != nil {
		utils.NotFound(c, "user not found")
		return
	}
	utils.OK(c, user)
}

func (h *Handler) UpdateProfile(c *gin.Context) {
	userID := c.GetString("user_id")
	var body struct {
		FullName  string  `json:"full_name" binding:"required,min=2"`
		AvatarURL *string `json:"avatar_url"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}

	user, err := h.svc.UpdateProfile(c.Request.Context(), userID, body.FullName, body.AvatarURL)
	if err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, user)
}