package pb

import (
	"github.com/ChausseBenjamin/rafta/pkg/model"
	"google.golang.org/grpc"
)

func Setup(conn *grpc.ClientConn) model.RaftaClient {
	return model.NewRaftaClient(conn)
}
