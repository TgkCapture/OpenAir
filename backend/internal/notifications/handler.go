package notifications

import (
	"log"

	"github.com/gin-gonic/gin"
	"github.com/TgkCapture/openair/pkg/utils"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) RegisterToken(c *gin.Context) {
	var req RegisterTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}
	userID := c.GetString("user_id")
	if err := h.svc.RegisterToken(c.Request.Context(), userID, req.Token, req.DeviceType); err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, gin.H{"message": "token registered"})
}

// UnregisterToken stops push delivery to a device, for example on sign-out.
func (h *Handler) UnregisterToken(c *gin.Context) {
	var req UnregisterTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}
	userID := c.GetString("user_id")
	if err := h.svc.UnregisterToken(c.Request.Context(), userID, req.Token); err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, gin.H{"message": "token removed"})
}

func (h *Handler) GetNotifications(c *gin.Context) {
	userID := c.GetString("user_id")
	items, err := h.svc.GetUserNotifications(c.Request.Context(), userID)
	if err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, items)
}

func (h *Handler) MarkAllRead(c *gin.Context) {
	userID := c.GetString("user_id")
	if err := h.svc.MarkAllRead(c.Request.Context(), userID); err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, gin.H{"message": "marked as read"})
}

func (h *Handler) Send(c *gin.Context) {
	var req SendNotificationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}
	if !req.SendAll && len(req.UserIDs) == 0 {
		utils.BadRequest(c, "VALIDATION_ERROR", "set send_all or provide user_ids")
		return
	}
	result, err := h.svc.Send(c.Request.Context(), req)
	if err != nil {
		log.Printf("ERROR send notification: %v", err)
		utils.InternalError(c)
		return
	}
	utils.OK(c, result)
}