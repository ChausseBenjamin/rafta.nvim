package user

import (
	"context"
	"fmt"

	"github.com/ChausseBenjamin/rafta.nvim/rafta-remote/rafta-remote/internal/creds"
	"github.com/ChausseBenjamin/rafta/pkg/model"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
	"google.golang.org/protobuf/types/known/emptypb"
	"google.golang.org/protobuf/types/known/timestamppb"
)

// UserHandler acts as a bridge between gRPC RaftaClient and Neovim
type UserHandler struct {
	creds  *creds.Creds
	client model.RaftaClient
}

// NewUserHandler creates a new UserHandler with the given connection and credentials
func NewUserHandler(conn *grpc.ClientConn, credentials *creds.Creds) *UserHandler {
	client := model.NewRaftaClient(conn)
	return &UserHandler{
		creds:  credentials,
		client: client,
	}
}

// Helper function to create authenticated context
func (u *UserHandler) createAuthenticatedContext() (context.Context, error) {
	token, err := u.creds.GetBearer()
	if err != nil {
		return nil, fmt.Errorf("failed to get bearer token: %w", err)
	}

	md := metadata.Pairs("authorization", "Bearer "+token)
	return metadata.NewOutgoingContext(context.Background(), md), nil
}

// Bridge methods for RaftaClient interface

// GetAllTasks retrieves all tasks for the authenticated user
func (u *UserHandler) GetAllTasks() (*model.TaskList, error) {
	ctx, err := u.createAuthenticatedContext()
	if err != nil {
		return nil, err
	}

	return u.client.GetAllTasks(ctx, &emptypb.Empty{})
}

// GetTask retrieves a specific task by UUID
func (u *UserHandler) GetTask(taskID *model.UUID) (*model.Task, error) {
	ctx, err := u.createAuthenticatedContext()
	if err != nil {
		return nil, err
	}

	return u.client.GetTask(ctx, taskID)
}

// GetUserInfo retrieves information about the authenticated user
func (u *UserHandler) GetUserInfo() (*model.User, error) {
	ctx, err := u.createAuthenticatedContext()
	if err != nil {
		return nil, err
	}

	return u.client.GetUserInfo(ctx, &emptypb.Empty{})
}

// DeleteUser deletes the authenticated user account
func (u *UserHandler) DeleteUser() error {
	ctx, err := u.createAuthenticatedContext()
	if err != nil {
		return err
	}

	_, err = u.client.DeleteUser(ctx, &emptypb.Empty{})
	return err
}

// UpdateCredentials updates the user's password
func (u *UserHandler) UpdateCredentials(passwdMsg *model.PasswdMessage) (*timestamppb.Timestamp, error) {
	ctx, err := u.createAuthenticatedContext()
	if err != nil {
		return nil, err
	}

	return u.client.UpdateCredentials(ctx, passwdMsg)
}

// UpdateUserInfo updates the user's profile information
func (u *UserHandler) UpdateUserInfo(userData *model.UserData) (*timestamppb.Timestamp, error) {
	ctx, err := u.createAuthenticatedContext()
	if err != nil {
		return nil, err
	}

	return u.client.UpdateUserInfo(ctx, userData)
}

// NewTask creates a new task
func (u *UserHandler) NewTask(taskData *model.TaskData) (*model.NewTaskResponse, error) {
	ctx, err := u.createAuthenticatedContext()
	if err != nil {
		return nil, err
	}

	return u.client.NewTask(ctx, taskData)
}

// DeleteTask deletes a task by UUID
func (u *UserHandler) DeleteTask(taskID *model.UUID) error {
	ctx, err := u.createAuthenticatedContext()
	if err != nil {
		return err
	}

	_, err = u.client.DeleteTask(ctx, taskID)
	return err
}

// UpdateTask updates an existing task
func (u *UserHandler) UpdateTask(updateReq *model.TaskUpdateRequest) (*model.TaskUpdateResponse, error) {
	ctx, err := u.createAuthenticatedContext()
	if err != nil {
		return nil, err
	}

	return u.client.UpdateTask(ctx, updateReq)
}

// Convenience methods for easier Neovim integration

// GetAllTasksSimple returns all tasks as a simple interface for Neovim
func (u *UserHandler) GetAllTasksSimple() (any, error) {
	tasks, err := u.GetAllTasks()
	if err != nil {
		return nil, err
	}
	return tasks, nil
}

// GetUserInfoSimple returns user info as a simple interface for Neovim
func (u *UserHandler) GetUserInfoSimple() (any, error) {
	user, err := u.GetUserInfo()
	if err != nil {
		return nil, err
	}
	return user, nil
}
