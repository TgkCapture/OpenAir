package podcasts

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
	podcasts, err := h.svc.GetAll(c.Request.Context())
	if err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, podcasts)
}

func (h *Handler) GetByID(c *gin.Context) {
	p, err := h.svc.GetByID(c.Request.Context(), c.Param("id"))
	if err != nil {
		if errors.Is(err, ErrPodcastNotFound) {
			utils.NotFound(c, "podcast not found")
			return
		}
		utils.InternalError(c)
		return
	}
	utils.OK(c, p)
}

func (h *Handler) GetEpisodes(c *gin.Context) {
	episodes, err := h.svc.GetEpisodes(c.Request.Context(), c.Param("id"))
	if err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, episodes)
}

func (h *Handler) GetEpisodeStreamURL(c *gin.Context) {
	userRole := c.GetString("user_role")
	isPremium := userRole == "admin"

	url, err := h.svc.GetEpisodeStreamURL(c.Request.Context(), c.Param("episodeId"), isPremium)
	if err != nil {
		if errors.Is(err, ErrEpisodeNotFound) {
			utils.NotFound(c, "episode not found")
			return
		}
		if errors.Is(err, ErrPremiumRequired) {
			c.JSON(http.StatusForbidden, utils.Response{
				Success: false,
				Error:   &utils.APIError{Code: "PREMIUM_REQUIRED", Message: "premium required"},
			})
			return
		}
		utils.InternalError(c)
		return
	}
	utils.OK(c, gin.H{"url": url})
}

func (h *Handler) CreatePodcast(c *gin.Context) {
	var req CreatePodcastRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}
	p, err := h.svc.CreatePodcast(c.Request.Context(), req)
	if err != nil {
		utils.InternalError(c)
		return
	}
	utils.Created(c, p)
}

func (h *Handler) CreateEpisode(c *gin.Context) {
	var req CreateEpisodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}
	p, err := h.svc.CreateEpisode(c.Request.Context(), req)
	if err != nil {
		utils.InternalError(c)
		return
	}
	utils.Created(c, p)
}