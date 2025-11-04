package conn

import (
	"crypto/tls"
	"fmt"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/credentials/insecure"
)

const (
	DefaultPort = 1157
	DefaultHost = "localhost"
)

type config struct {
	allowInsecure bool
	host          string
	port          int
}

type Option func(*config)

func WithHost(host string) Option {
	return func(c *config) {
		c.host = host
	}
}

func WithPort(port int) Option {
	return func(c *config) {
		c.port = port
	}
}

func WithInsecureConnectivity() Option {
	return func(c *config) {
		c.allowInsecure = true
	}
}

func New(opts ...Option) (*grpc.ClientConn, error) {
	cfg := &config{
		host:          DefaultHost,
		port:          DefaultPort,
		allowInsecure: false,
	}

	for _, opt := range opts {
		opt(cfg)
	}

	target := fmt.Sprintf("%s:%d", cfg.host, cfg.port)

	var dialOpts []grpc.DialOption
	if cfg.allowInsecure {
		dialOpts = append(dialOpts, grpc.WithTransportCredentials(insecure.NewCredentials()))
	} else {
		// Use TLS credentials for secure connections
		tlsConfig := &tls.Config{
			ServerName: cfg.host,
		}
		dialOpts = append(dialOpts, grpc.WithTransportCredentials(credentials.NewTLS(tlsConfig)))
	}

	conn, err := grpc.Dial(target, dialOpts...)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to %s: %w", target, err)
	}

	return conn, nil
}
