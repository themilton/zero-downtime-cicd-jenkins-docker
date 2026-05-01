# Zero-Downtime CI/CD with Jenkins, Docker, and Nginx

A production CI/CD pipeline with blue-green deployments, automated health checks, and instant rollbacks — built after a Friday-evening "small fix" took down the app for 40 minutes.

## The flow

```
push to GitHub
   → Jenkins webhook
      → docker build
         → unit + integration tests
            → push to private registry
               → deploy to staging slot
                  → health check
                     → swap Nginx upstream (blue ↔ green)
                        → verify
                           → on failure, instant rollback
```

## Stack

| Component | Tool | Why |
|-----------|------|-----|
| CI server | Jenkins LTS (self-hosted) | Free, scriptable, already running on the homelab |
| Containers | Docker + Compose | Reproducible envs, trivial rollbacks |
| Reverse proxy | Nginx | Blue-green upstream swap, SSL termination |
| Source | GitHub | Webhook on push |
| Monitoring | Prometheus + Grafana | Alert before users do |
| Notifications | Slack webhook | Where I actually look |

## Topics

`DevOps` · `CI/CD` · `Jenkins` · `Docker` · `Nginx` · `Linux`

## Read the full write-up

[reshamchaudhary.com/blog/zero-downtime-cicd-jenkins-docker](https://reshamchaudhary.com/blog/zero-downtime-cicd-jenkins-docker)

The blog post has the full Jenkins compose file, the declarative `Jenkinsfile`, the Nginx upstream-swap snippet, the rollback script, and the postmortem from the outage that started all this.
