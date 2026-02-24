# Load Distribution Test

## Objective
Verify that the Application Load Balancer distributes incoming requests across multiple healthy EC2 instances.

---

## Test Setup
- Application Load Balancer (internet-facing)
- Target group with 3 registered EC2 instances
- Each instance returns instance-specific information in the response

---

## Test Methodology
Repeated HTTP requests were sent to the ALB DNS endpoint using `curl`.  
The instance identifier in each response was observed to confirm traffic distribution.

Command used:
```bash
for i in {1..20}; do
  curl -s http://<ALB-DNS> | grep "Instance"
done

```

## Results

- Responses alternated between different instance identifiers
- All registered instances received traffic
- Distribution was roughly even over multiple requests

---

## Conclusion

The Application Load Balancer successfully distributes traffic across all healthy application instances, confirming correct load balancing behavior.