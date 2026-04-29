package channels

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/TgkCapture/openair/pkg/utils"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) GetAll(c *gin.Context) {
	channelType := c.Query("type")
	channels, err := h.svc.GetAll(c.Request.Context(), channelType)
	if err != nil {
		utils.InternalError(c)
		return
	}
	if channels == nil {
		channels = []*Channel{}
	}
	utils.OK(c, channels)
}

func (h *Handler) GetByID(c *gin.Context) {
	ch, err := h.svc.GetByID(c.Request.Context(), c.Param("id"))
	if err != nil {
		if errors.Is(err, ErrChannelNotFound) {
			utils.NotFound(c, "channel not found")
			return
		}
		utils.InternalError(c)
		return
	}
	utils.OK(c, ch)
}

func (h *Handler) GetStreamURL(c *gin.Context) {
	userID := c.GetString("user_id")
	userRole := c.GetString("user_role")

	isPremium, err := h.svc.isUserPremium(c.Request.Context(), userID, userRole)
	if err != nil {
		utils.InternalError(c)
		return
	}

	resp, err := h.svc.GetStreamURL(c.Request.Context(), c.Param("id"), userID, isPremium)
	if err != nil {
		if errors.Is(err, ErrChannelNotFound) {
			utils.NotFound(c, "channel not found")
			return
		}
		if errors.Is(err, ErrPremiumRequired) {
			c.JSON(http.StatusForbidden, utils.Response{
				Success: false,
				Error:   &utils.APIError{Code: "PREMIUM_REQUIRED", Message: "premium subscription required"},
			})
			return
		}
		utils.InternalError(c)
		return
	}
	utils.OK(c, resp)
}

// Public stream URL — no auth required for free channels
func (h *Handler) GetPublicStreamURL(c *gin.Context) {
	resp, err := h.svc.GetStreamURL(c.Request.Context(), c.Param("id"), "", false)
	if err != nil {
		if errors.Is(err, ErrChannelNotFound) {
			utils.NotFound(c, "channel not found")
			return
		}
		if errors.Is(err, ErrPremiumRequired) {
			c.JSON(http.StatusForbidden, utils.Response{
				Success: false,
				Error:   &utils.APIError{Code: "PREMIUM_REQUIRED", Message: "login required for premium channels"},
			})
			return
		}
		utils.InternalError(c)
		return
	}
	utils.OK(c, resp)
}

func (h *Handler) Create(c *gin.Context) {
	var req CreateChannelRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}
	ch, err := h.svc.Create(c.Request.Context(), req)
	if err != nil {
		utils.InternalError(c)
		return
	}
	utils.Created(c, ch)
}

func (h *Handler) Update(c *gin.Context) {
	var req UpdateChannelRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}
	ch, err := h.svc.Update(c.Request.Context(), c.Param("id"), req)
	if err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, ch)
}

func (h *Handler) Delete(c *gin.Context) {
	if err := h.svc.Delete(c.Request.Context(), c.Param("id")); err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, gin.H{"message": "channel deleted"})
}

func (h *Handler) ToggleAccess(c *gin.Context) {
	var body struct {
		IsPremium bool `json:"is_premium"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}
	ch, err := h.svc.ToggleAccess(c.Request.Context(), c.Param("id"), body.IsPremium)
	if err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, ch)
}