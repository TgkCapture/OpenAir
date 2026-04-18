package utils

import (
    "net/http"

    "github.com/gin-gonic/gin"
)

type Response struct {
    Success bool        `json:"success"`
    Data    interface{} `json:"data,omitempty"`
    Error   *APIError   `json:"error,omitempty"`
    Meta    *Meta       `json:"meta,omitempty"`
}

type APIError struct {
    Code    string `json:"code"`
    Message string `json:"message"`
}

type Meta struct {
    Page    int `json:"page,omitempty"`
    PerPage int `json:"per_page,omitempty"`
    Total   int `json:"total,omitempty"`
}

func OK(c *gin.Context, data interface{}) {
    c.JSON(http.StatusOK, Response{Success: true, Data: data})
}

func Created(c *gin.Context, data interface{}) {
    c.JSON(http.StatusCreated, Response{Success: true, Data: data})
}

func OKWithMeta(c *gin.Context, data interface{}, meta *Meta) {
    c.JSON(http.StatusOK, Response{Success: true, Data: data, Meta: meta})
}

func BadRequest(c *gin.Context, code, message string) {
    c.JSON(http.StatusBadRequest, Response{
        Success: false,
        Error:   &APIError{Code: code, Message: message},
    })
}

func Unauthorized(c *gin.Context, code, message string) {
    c.JSON(http.StatusUnauthorized, Response{
        Success: false,
        Error:   &APIError{Code: code, Message: message},
    })
}

func Forbidden(c *gin.Context, code, message string) {
    c.JSON(http.StatusForbidden, Response{
        Success: false,
        Error:   &APIError{Code: code, Message: message},
    })
}

func NotFound(c *gin.Context, message string) {
    c.JSON(http.StatusNotFound, Response{
        Success: false,
        Error:   &APIError{Code: "NOT_FOUND", Message: message},
    })
}

func Conflict(c *gin.Context, code, message string) {
    c.JSON(http.StatusConflict, Response{
        Success: false,
        Error:   &APIError{Code: code, Message: message},
    })
}

func InternalError(c *gin.Context) {
    c.JSON(http.StatusInternalServerError, Response{
        Success: false,
        Error:   &APIError{Code: "INTERNAL_ERROR", Message: "an unexpected error occurred"},
    })
}