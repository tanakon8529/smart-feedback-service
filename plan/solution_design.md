# Smart Feedback Analysis Service - Solution Design

## 1. Overview
This document outlines the architecture for the Smart Feedback Analysis Service. The goal is to build a high-performance, scalable microservice that ingests customer feedback, analyzes it using AI (LLM) for sentiment and categorization, and provides a dashboard for insights.

While the immediate requirement is a 4-hour coding challenge, this design reflects a production-ready, cloud-native architecture on AWS, capable of handling massive scale.

## 2. Architecture: AWS Cloud-Native (Multi-Scale)

To meet the "Super High Performance" and "Secure" requirements, we design a split-microservice architecture deployed on AWS EKS (Elastic Kubernetes Service) within a VPC.

### 2.1 High-Level Diagram
```mermaid
graph TD
    Client[Client App/Web] -->|HTTPS| CDN[CloudFront]
    CDN -->|WAF Protection| APIG[API Gateway]
    
    subgraph "AWS Cloud (VPC)"
        APIG -->|OAuth2 Auth| ALB[Application Load Balancer]
        
        subgraph "Public Subnet (DMZ)"
            NAT[NAT Gateway]
        end
        
        subgraph "Private Subnet (EKS Cluster)"
            Ingress[Ingress Controller]
            
            subgraph "Services"
                API[Feedback Ingestion Service]
                Worker[AI Analysis Worker]
                Dash[Dashboard Service]
            end
            
            API -->|Produce Event| Kafka[MSK / RabbitMQ]
            Kafka -->|Consume| Worker
            Worker -->|Write| DB_Master
            Dash -->|Read| DB_ReadReplica
        end
        
        subgraph "Data Layer"
            DB_Master[(PostgreSQL / Aurora)]
            DB_ReadReplica[(Read Replica)]
            VectorDB[(Vector DB / pgvector)]
            DynamoDB[(DynamoDB - Audit/Logs)]
        end
    end
    
    Worker -->|Call| LLM[LLM Gateway (OpenAI/Claude)]
    Worker -->|Log| CW[CloudWatch Logs]
    
    classDef aws fill:#ff9900,stroke:#232f3e,stroke-width:2px,color:white;
    class APIG,ALB,NAT,DB_Master,DynamoDB,CW,VectorDB aws;
```

### 2.2 Components

1.  **Network & Security**:
    -   **VPC**: Custom VPC with Public (ALB, NAT) and Private (EKS Nodes, DB) subnets.
    -   **AWS WAF & Shield**: Protects API Gateway/ALB from DDoS and common web exploits.
    -   **API Gateway**: Entry point, handling rate limiting and initial routing.
    -   **Authentication**: OAuth2 via Cognito or external provider, validated at the Gateway or Ingress level.

2.  **Compute (EKS Microservices)**:
    -   **Ingestion Service (FastAPI)**: 
        -   Endpoint: `POST /feedback`
        -   Responsibility: Validate input, push to Queue, return 202 Accepted immediately.
        -   Scalability: Stateless, horizontal autoscaling (HPA) based on CPU/Memory.
    -   **Analysis Worker (Python + PydanticAI)**:
        -   Responsibility: Consume message, call LLM, process result, save to DB.
        -   AI Stack: `pydantic-ai` for structured prompting and validation.
    -   **Dashboard Service (FastAPI)**:
        -   Endpoint: `GET /dashboard/stats`
        -   Responsibility: Aggregation queries, caching (Redis).

3.  **Data Layer**:
    -   **SQL Database (PostgreSQL/Aurora)**: Stores structured feedback data (Customer, Message, Sentiment, Category).
    -   **Vector DB (e.g., pgvector or Qdrant)**: Stores embeddings of feedback messages for RAG (Retrieval Augmented Generation) to support future "similar feedback" queries.
    -   **DynamoDB**: High-speed storage for raw audit logs or user session data (if needed).

4.  **Observability**:
    -   **CloudWatch**: Logs and Metrics.
    -   **X-Ray**: Distributed tracing to see latency between Ingestion -> Queue -> Worker -> LLM.

## 3. Tech Stack (Implementation Focus)

For the 4-hour challenge, we will simulate this architecture using `docker-compose` but structure the code to be "Cloud-Ready".

-   **Language**: Python 3.11+
-   **Web Framework**: FastAPI (Async, High Performance).
-   **AI Library**: `pydantic-ai` (for type-safe LLM interactions).
-   **Database**: PostgreSQL (SQL requirement).
-   **ORM**: SQLModel (Pydantic + SQLAlchemy) or Prisma.
-   **Containerization**: Docker & Docker Compose.

## 4. Implementation Steps (Challenge Scope)

1.  **Setup**: Init Project, Poetry/Pipenv, Docker Compose (App + DB).
2.  **Database Design**: Define `Feedback` table with fields: `id`, `message`, `sentiment`, `category`, `summary`, `created_at`.
3.  **API Implementation (`POST /feedback`)**:
    -   Use `pydantic-ai` to define the LLM Model.
    -   Create a "Mock" LLM provider for the challenge (to save cost/time) but with an interface ready for OpenAI.
    -   Implement async processing (simulate worker).
4.  **API Implementation (`GET /dashboard/stats`)**:
    -   Write optimized SQL aggregation query.
5.  **Testing**: Unit tests with `pytest`.
6.  **Documentation**: `AI_LOG.md` and `README.md`.

## 5. AI-Driven Development Strategy
-   **Code Generation**: Use Cursor/Trae/Copilot to generate Pydantic models and boilerplate FastAPI code.
-   **SQL Optimization**: Ask AI to generate the most efficient SQL query for the stats endpoint.
-   **Test Generation**: Use AI to generate test cases covering edge cases.

---
**Note**: The actual implementation will combine Ingestion and Worker into a single service for the 4-hour constraint, but code will be modular to split easily later.
