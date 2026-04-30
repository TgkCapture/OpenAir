package notifications

type FCMToken struct {
	UserID     string `json:"user_id"`
	Token      string `json:"token"`
	DeviceType string `json:"device_type"`
}

type RegisterTokenRequest struct {
	Token      string `json:"token" binding:"required"`
	DeviceType string `json:"device_type" binding:"required,oneof=android ios"`
}

type SendNotificationRequest struct {
	Title    string   `json:"title" binding:"required"`
	Body     string   `json:"body" binding:"required"`
	UserIDs  []string `json:"user_ids"`
	SendAll  bool     `json:"send_all"`
	ImageURL string   `json:"image_url"`
	Data     map[string]string `json:"data"`
}

type FCMMessage struct {
	Message FCMMessageBody `json:"message"`
}

type FCMMessageBody struct {
	Token        string            `json:"token,omitempty"`
	Notification FCMNotification   `json:"notification"`
	Data         map[string]string `json:"data,omitempty"`
}

type FCMNotification struct {
	Title    string `json:"title"`
	Body     string `json:"body"`
	ImageURL string `json:"image,omitempty"`
}