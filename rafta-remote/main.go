package main

import (
	"fmt"
	"log"
	"os"

	"github.com/ChausseBenjamin/rafta.nvim/rafta-remote/rafta-remote/internal/conn"
	"github.com/ChausseBenjamin/rafta.nvim/rafta-remote/rafta-remote/internal/creds"
	"github.com/ChausseBenjamin/rafta.nvim/rafta-remote/rafta-remote/internal/user"
	"github.com/ChausseBenjamin/rafta/pkg/model"
	"github.com/neovim/go-client/nvim"
)

type RemoteSetup struct {
	User       string `msgpack:"user"`
	Pass       string `msgpack:"pass"`
	Host       string `msgpack:"host"`
	Port       uint   `msgpack:"port"`
	DisableSSL bool   `msgpack:"disableSSL"`
}

// Global userHandler instance for RaftaClient bridge
var globalUserHandler *user.UserHandler

func setupHandler(args RemoteSetup) (any, error) {
	connOpts := []conn.Option{
		conn.WithHost(args.Host),
		conn.WithPort(int(args.Port)),
	}

	if args.DisableSSL {
		connOpts = append(connOpts, conn.WithInsecureConnectivity())
	}

	connection, err := conn.New(connOpts...)
	if err != nil {
		return nil, fmt.Errorf("failed to create connection: %w", err)
	}

	credentials := creds.Setup(connection, args.User, args.Pass)

	// Create global userHandler for RaftaClient bridge
	globalUserHandler = user.NewUserHandler(connection, credentials)

	return map[string]interface{}{
		"status":  "success",
		"message": "Remote setup completed successfully",
	}, nil
}

// RaftaClient bridge handlers for Neovim

func getAllTasksHandler(args any) (any, error) {
	if globalUserHandler == nil {
		return nil, fmt.Errorf("user handler not initialized - run Setup first")
	}
	return globalUserHandler.GetAllTasksSimple()
}

func getTaskHandler(args *model.UUID) (*model.Task, error) {
	if globalUserHandler == nil {
		return nil, fmt.Errorf("user handler not initialized - run Setup first")
	}
	return globalUserHandler.GetTask(args)
}

func getUserInfoHandler(args any) (any, error) {
	if globalUserHandler == nil {
		return nil, fmt.Errorf("user handler not initialized - run Setup first")
	}
	return globalUserHandler.GetUserInfoSimple()
}

func deleteUserHandler(args any) (any, error) {
	if globalUserHandler == nil {
		return nil, fmt.Errorf("user handler not initialized - run Setup first")
	}
	err := globalUserHandler.DeleteUser()
	if err != nil {
		return nil, err
	}
	return map[string]string{"status": "user deleted successfully"}, nil
}

func updateCredentialsHandler(args *model.PasswdMessage) (any, error) {
	if globalUserHandler == nil {
		return nil, fmt.Errorf("user handler not initialized - run Setup first")
	}
	return globalUserHandler.UpdateCredentials(args)
}

func updateUserInfoHandler(args *model.UserData) (any, error) {
	if globalUserHandler == nil {
		return nil, fmt.Errorf("user handler not initialized - run Setup first")
	}
	return globalUserHandler.UpdateUserInfo(args)
}

func newTaskHandler(args *model.TaskData) (*model.NewTaskResponse, error) {
	if globalUserHandler == nil {
		return nil, fmt.Errorf("user handler not initialized - run Setup first")
	}
	return globalUserHandler.NewTask(args)
}

func deleteTaskHandler(args *model.UUID) (any, error) {
	if globalUserHandler == nil {
		return nil, fmt.Errorf("user handler not initialized - run Setup first")
	}
	err := globalUserHandler.DeleteTask(args)
	if err != nil {
		return nil, err
	}
	return map[string]string{"status": "task deleted successfully"}, nil
}

func updateTaskHandler(args *model.TaskUpdateRequest) (*model.TaskUpdateResponse, error) {
	if globalUserHandler == nil {
		return nil, fmt.Errorf("user handler not initialized - run Setup first")
	}
	return globalUserHandler.UpdateTask(args)
}

func main() {
	// Turn off timestamps in output.
	log.SetFlags(0)

	// Direct writes by the application to stdout garble the RPC stream.
	// Redirect the application's direct use of stdout to stderr.
	stdout := os.Stdout
	os.Stdout = os.Stderr

	// Create a client connected to stdio. Configure the client to use the
	// standard log package for logging.
	v, err := nvim.New(os.Stdin, stdout, stdout, log.Printf)
	if err != nil {
		log.Fatal(err)
	}

	// Register function with the client.
	v.RegisterHandler("Setup", setupHandler)

	// Register RaftaClient bridge handlers
	v.RegisterHandler("GetAllTasks", getAllTasksHandler)
	v.RegisterHandler("GetTask", getTaskHandler)
	v.RegisterHandler("GetUserInfo", getUserInfoHandler)
	v.RegisterHandler("DeleteUser", deleteUserHandler)
	v.RegisterHandler("UpdateCredentials", updateCredentialsHandler)
	v.RegisterHandler("UpdateUserInfo", updateUserInfoHandler)
	v.RegisterHandler("NewTask", newTaskHandler)
	v.RegisterHandler("DeleteTask", deleteTaskHandler)
	v.RegisterHandler("UpdateTask", updateTaskHandler)

	// Run the RPC message loop. The Serve function returns when
	// nvim closes.
	if err := v.Serve(); err != nil {
		log.Fatal(err)
	}
}
