package schedule

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/TgkCapture/openair/pkg/utils"
)

type Handler struct {
	repo *Repository
}

func NewHandler(repo *Repository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) GetByChannel(c *gin.Context) {
	channelID := c.Param("channelId")
	dateStr := c.DefaultQuery("date", time.Now().UTC().Format("2006-01-02"))

	date, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", "invalid date format, use YYYY-MM-DD")
		return
	}

	programmes, err := h.repo.GetByChannel(c.Request.Context(), channelID, date)
	if err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, programmes)
}

func (h *Handler) GetNowAndNext(c *gin.Context) {
	nn, err := h.repo.GetNowAndNext(c.Request.Context(), c.Param("channelId"))
	if err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, nn)
}

func (h *Handler) GetAllNowAndNext(c *gin.Context) {
	result, err := h.repo.GetAllNowAndNext(c.Request.Context())
	if err != nil {
		utils.InternalError(c)
		return
	}
	if result == nil {
		result = []*NowAndNext{}
	}
	utils.OK(c, result)
}

func (h *Handler) Create(c *gin.Context) {
	var req CreateProgrammeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}
	if req.EndsAt.Before(req.StartsAt) {
		utils.BadRequest(c, "VALIDATION_ERROR", "ends_at must be after starts_at")
		return
	}
	p, err := h.repo.Create(c.Request.Context(), req)
	if err != nil {
		utils.InternalError(c)
		return
	}
	c.JSON(http.StatusCreated, utils.Response{Success: true, Data: p})
}

func (h *Handler) Update(c *gin.Context) {
	var req UpdateProgrammeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}
	p, err := h.repo.Update(c.Request.Context(), c.Param("id"), req)
	if err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, p)
}

func (h *Handler) Delete(c *gin.Context) {
	if err := h.repo.Delete(c.Request.Context(), c.Param("id")); err != nil {
		utils.InternalError(c)
		return
	}
	utils.OK(c, gin.H{"message": "deleted"})
}