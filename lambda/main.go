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
	// Get the source control information for the current build
	vcsInfo *vcs.Info = vcs.GetInfo()
)

func main() {
	// Make the handler available for Remote Procedure Call by AWS Lambda
	lambda.Start(handler)
}

// handler is the main Lambda entry point for the request/response cycle
func handler(ctx context.Context, event events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	fmt.Printf("Begin Request\n")
	defer fmt.Printf("Request Completed\n")

	// Delegate request based on routing key
	switch event.RouteKey {
	case "GET /":
		return handleGetRoot(ctx, event)
	case "GET /build-info":
		return handleGetBuildInfo(ctx, event)
	}

	// Return an error if no route was matched
	return events.APIGatewayV2HTTPResponse{
		StatusCode: http.StatusInternalServerError,
		Body:       "Cannot handle request",
	}, nil
}

// handleGetRoot is the default handler for the root path
// and returns a simple 'Hello, World!' response
func handleGetRoot(ctx context.Context, event events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	return events.APIGatewayV2HTTPResponse{
		StatusCode: http.StatusOK,
		Body:       "Hello, World!",
	}, nil
}

// handleGetBuildInfo is the handler for the /build-info path
// and returns a JSON response of the source control information
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
