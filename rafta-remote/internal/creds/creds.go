package creds

import (
	"context"
	"encoding/base64"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/ChausseBenjamin/rafta/pkg/model"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
	"google.golang.org/protobuf/types/known/emptypb"
)

type Creds struct {
	client model.AuthClient

	user string
	pass string

	// Internal
	initialized bool // defaults to false which is useful
	access      *token
	refresh     *token
}

type token struct {
	expiry time.Time // unmarshalled on reception -> avoids un-necessary refreshes
	raw    string    // What is added to the headers
}

func Setup(conn *grpc.ClientConn, user string, pass string) *Creds {
	var client model.AuthClient
	if conn != nil {
		client = model.NewAuthClient(conn)
	}
	return &Creds{
		initialized: true,
		client:      client,
		user:        user,
		pass:        pass,
	}
}

// Helper function to parse JWT token and extract expiry
func parseJWTToken(tokenStr string) *token {
	if tokenStr == "" {
		return nil
	}

	// For simplicity, we'll set expiry to 1 hour from now
	// In a real implementation, you'd parse the JWT to get the actual expiry
	expiry := time.Now().Add(time.Hour)

	// TODO: Parse actual JWT to extract exp claim
	// For now, assume tokens are valid for 1 hour
	parts := strings.Split(tokenStr, ".")
	if len(parts) == 3 {
		// Try to decode the payload to get expiry
		payload, err := base64.RawURLEncoding.DecodeString(parts[1])
		if err == nil {
			// Simple parsing - in production you'd use a proper JWT library
			payloadStr := string(payload)
			if strings.Contains(payloadStr, `"exp":`) {
				// Extract exp value - this is a simplified approach
				start := strings.Index(payloadStr, `"exp":`) + 6
				end := strings.Index(payloadStr[start:], ",")
				if end == -1 {
					end = strings.Index(payloadStr[start:], "}")
				}
				if end != -1 {
					expStr := strings.TrimSpace(payloadStr[start : start+end])
					if exp, err := strconv.ParseInt(expStr, 10, 64); err == nil {
						expiry = time.Unix(exp, 0)
					}
				}
			}
		}
	}

	return &token{
		expiry: expiry,
		raw:    tokenStr,
	}
}

// Helper function to check if token is expired
func (t *token) isExpired() bool {
	if t == nil {
		return true
	}
	return time.Now().After(t.expiry)
}

// Helper function to create context with Basic auth
func (c *Creds) createAuthContext() context.Context {
	auth := base64.StdEncoding.EncodeToString([]byte(fmt.Sprintf("%s:%s", c.user, c.pass)))
	md := metadata.Pairs("authorization", "Basic "+auth)
	return metadata.NewOutgoingContext(context.Background(), md)
}

// Helper function to create context with Bearer token
func createBearerContext(token string) context.Context {
	md := metadata.Pairs("authorization", "Bearer "+token)
	return metadata.NewOutgoingContext(context.Background(), md)
}

func (c *Creds) GetBearer() (string, error) {
	// Check if client connection is configured
	if c.client == nil {
		return "", errors.New("no gRPC client connection configured")
	}

	// If access token exists and is not expired, return cached bearer
	if c.access != nil && !c.access.isExpired() {
		return c.access.raw, nil
	}

	// If refresh token exists and is not expired, use it to refresh
	if c.refresh != nil && !c.refresh.isExpired() {
		ctx := createBearerContext(c.refresh.raw)
		resp, err := c.client.Refresh(ctx, &emptypb.Empty{})
		if err != nil {
			return "", fmt.Errorf("failed to refresh token: %w", err)
		}

		// Update cached tokens
		c.access = parseJWTToken(resp.GetAccess())
		c.refresh = parseJWTToken(resp.GetRefresh())

		if c.access == nil {
			return "", errors.New("received nil access token from refresh")
		}

		return c.access.raw, nil
	}

	// In any other case, use user/pass to login and cache new token pair
	ctx := c.createAuthContext()
	resp, err := c.client.Login(ctx, &emptypb.Empty{})
	if err != nil {
		return "", fmt.Errorf("failed to login: %w", err)
	}

	tokens := resp.GetTokens()
	if tokens == nil {
		return "", errors.New("received nil tokens from login")
	}

	// Cache the new token pair
	c.access = parseJWTToken(tokens.GetAccess())
	c.refresh = parseJWTToken(tokens.GetRefresh())

	if c.access == nil {
		return "", errors.New("received nil access token from login")
	}

	return c.access.raw, nil
}
