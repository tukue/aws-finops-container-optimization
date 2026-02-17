# Event-Driven React & FastAPI Application

A modern event-driven architecture implementation using React frontend and FastAPI backend with real-time communication.

## Architecture Overview

This application demonstrates event-driven patterns with:
- **FastAPI Backend**: Async API with WebSocket support and event publishing
- **React Frontend**: Real-time UI with event subscriptions
- **Redis**: Event streaming and caching
- **PostgreSQL**: Event store and application data
- **Docker**: Containerized development environment

## Key Features

- Real-time event streaming via WebSockets
- Event sourcing with persistent event store
- Async task processing with background workers
- Real-time notifications and updates
- Scalable microservice architecture

## Quick Start

```bash
# Start all services
docker-compose up -d

# Access the application
Frontend: http://localhost:3000
Backend API: http://localhost:8000
API Docs: http://localhost:8000/docs
```

## Project Structure

```
├── backend/           # FastAPI application
├── frontend/          # React application
├── docker-compose.yml # Development environment
└── docs/             # Documentation
```