package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/m13t/heni-tech-test/lambda/internal/vcs"
)

var (
	vcsInfo *vcs.Info = vcs.GetInfo()
)

func main() {
	lambda.Start(handler)
}

func handler(ctx context.Context, event events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	fmt.Printf("Begin Request\n")
	defer fmt.Printf("Request Completed\n")

	switch event.RouteKey {
	case "GET /":
		return handleGetRoot(ctx, event)
	case "GET /build-info":
		return handleGetBuildInfo(ctx, event)
	}

	return events.APIGatewayV2HTTPResponse{
		StatusCode: http.StatusInternalServerError,
		Body:       "Cannot handle request",
	}, nil
}

func handleGetRoot(ctx context.Context, event events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	return events.APIGatewayV2HTTPResponse{
		StatusCode: http.StatusOK,
		Body:       "Hello, World!",
	}, nil
}

func handleGetBuildInfo(ctx context.Context, event events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	if vcsInfo != nil {
		vi, err := json.MarshalIndent(vcsInfo, "", "\t")
		if err != nil {
			return events.APIGatewayV2HTTPResponse{
				StatusCode: http.StatusInternalServerError,
			}, err
		}

		return events.APIGatewayV2HTTPResponse{
			StatusCode: http.StatusOK,
			Body:       string(vi),
		}, nil
	}

	return events.APIGatewayV2HTTPResponse{
		StatusCode: 200,
		Body:       "No build info available",
	}, nil
}
