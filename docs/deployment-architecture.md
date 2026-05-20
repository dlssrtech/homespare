# Production Deployment Architecture

## Runtime Topology
- **Frontend**: Flutter apps distributed via stores; React admin on CDN.
- **Backend**: Containerized services on Kubernetes (EKS/GKE/AKS).
- **Data Layer**:
  - PostgreSQL (managed, Multi-AZ)
  - Redis (cache/session/rate limiting)
  - Object storage (S3/GCS) for proofs, designs, invoices
- **Async Layer**: Kafka or SQS/SNS for event processing.
- **Observability**: Prometheus + Grafana + OpenTelemetry + centralized logs.

## Scalability Patterns
- HPA based on CPU + queue lag.
- Read replicas for analytics/report queries.
- CQRS read models for dashboards.
- CDN edge caching for static assets.

## Security & Compliance
- WAF + API gateway throttling.
- Secrets manager + KMS encryption.
- VPC private subnets for DB and queues.
- Automated backups + PITR.

## CI/CD
- GitHub Actions / GitLab CI:
  1. lint + test + SAST
  2. build images
  3. deploy to staging
  4. integration tests
  5. progressive production rollout (canary/blue-green)
