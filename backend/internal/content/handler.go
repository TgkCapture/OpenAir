package content

import (
	"errors"
	"log"
	"net/http"
	"strconv"

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
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	perPage, _ := strconv.Atoi(c.DefaultQuery("per_page", "20"))

	result, err := h.svc.GetAll(
		c.Request.Context(),
		c.Query("type"),
		c.Query("category"),
		c.Query("q"),
		page, perPage,
	)
	if err != nil {
		log.Printf("ERROR GetAll content: %v", err)
		utils.InternalError(c)
		return
	}
	utils.OKWithMeta(c, result.Items, &utils.Meta{
		Page:    result.Page,
		PerPage: result.PerPage,
		Total:   result.Total,
	})
}

func (h *Handler) GetByID(c *gin.Context) {
	item, err := h.svc.GetByID(c.Request.Context(), c.Param("id"))
	if err != nil {
		if errors.Is(err, ErrContentNotFound) {
			utils.NotFound(c, "content not found")
			return
		}
		utils.InternalError(c)
		return
	}
	utils.OK(c, item)
}

func (h *Handler) GetStreamURL(c *gin.Context) {
	userID := c.GetString("user_id")
	userRole := c.GetString("user_role")
	isPremium := userRole == "admin"

	url, err := h.svc.GetStreamURL(c.Request.Context(), c.Param("id"), userID, isPremium)
	if err != nil {
		if errors.Is(err, ErrContentNotFound) {
			utils.NotFound(c, "content not found")
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
	utils.OK(c, gin.H{"url": url})
}

func (h *Handler) GetPublicStreamURL(c *gin.Context) {
	url, err := h.svc.GetStreamURL(c.Request.Context(), c.Param("id"), "", false)
	if err != nil {
		if errors.Is(err, ErrContentNotFound) {
			utils.NotFound(c, "content not found")
			return
		}
		if errors.Is(err, ErrPremiumRequired) {
			c.JSON(http.StatusForbidden, utils.Response{
				Success: false,
				Error:   &utils.APIError{Code: "PREMIUM_REQUIRED", Message: "login required for premium content"},
			})
			return
		}
		utils.InternalError(c)
		return
	}
	utils.OK(c, gin.H{"url": url})
}

func (h *Handler) GetCategories(c *gin.Context) {
	cats, err := h.svc.GetCategories(c.Request.Context())
	if err != nil {
		utils.InternalError(c)
		return
	}
	if cats == nil {
		cats = []string{}
	}
	utils.OK(c, cats)
}

func (h *Handler) SaveWatchHistory(c *gin.Context) {
	userID := c.GetString("user_id")
	var body struct {
		ContentID    string `json:"content_id" binding:"required"`
		ProgressSecs int    `json:"progress_secs"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}
	if err := h.svc.SaveWatchHistory(c.Request.Context(), userID, body.ContentID, body.ProgressSecs); err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, gin.H{"message": "saved"})
}

func (h *Handler) GetWatchHistory(c *gin.Context) {
	userID := c.GetString("user_id")
	items, err := h.svc.GetWatchHistory(c.Request.Context(), userID)
	if err != nil {
		utils.InternalError(c)
		return
	}
	if items == nil {
		items = []*Content{}
	}
	utils.OK(c, items)
}

func (h *Handler) Create(c *gin.Context) {
	var req CreateContentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}
	item, err := h.svc.Create(c.Request.Context(), req)
	if err != nil {
		utils.InternalError(c)
		return
	}
	utils.Created(c, item)
}

func (h *Handler) Update(c *gin.Context) {
	var req UpdateContentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}
	item, err := h.svc.Update(c.Request.Context(), c.Param("id"), req)
	if err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, item)
}

func (h *Handler) ToggleAccess(c *gin.Context) {
	var body struct {
		IsPremium bool `json:"is_premium"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}
	if err := h.svc.ToggleAccess(c.Request.Context(), c.Param("id"), body.IsPremium); err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, gin.H{"message": "access updated"})
}