```

## test-commands

**central place** for all commands used during testing.

```bash
#!/bin/bash

# Test basic connectivity to the Application Load Balancer
curl http://<ALB-DNS>

# Test health check endpoint
curl http://<ALB-DNS>/health

# Test load distribution across instances
for i in {1..10}; do
  curl -s http://<ALB-DNS> | grep "Instance"
done

# (Optional) After stopping one instance:
# Verify traffic continues to remaining healthy instances
for i in {1..10}; do
  curl -s http://<ALB-DNS> | grep "Instance"
done