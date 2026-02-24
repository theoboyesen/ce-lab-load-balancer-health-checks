# Load Balancer Testing – Three-Tier Project Extract

This document describes the **load balancing component** of a completed three-tier AWS architecture project.  
It focuses on **Application Load Balancer configuration, health checks, testing methodology, failover behavior, and best practices learned**.

The purpose of this README is to demonstrate understanding of how load balancers operate in a highly available cloud environment.

---

## Load Balancer Architecture Explanation

The application is fronted by an **internet-facing Application Load Balancer (ALB)** deployed across two public subnets in separate Availability Zones.

The ALB acts as the **single entry point** for all client traffic and distributes requests to the application tier, which consists of multiple EC2 instances running in private subnets.

High-level traffic flow:
Client → Application Load Balancer → Target Group → EC2 Application Instances


This architecture improves:
- Availability
- Fault tolerance
- Scalability

---

## Health Check Configuration & Rationale

The ALB target group is configured with an HTTP health check using the `/health` endpoint exposed by each application instance.

### Health Check Details
- **Protocol:** HTTP
- **Path:** `/health`
- **Port:** 80
- **Success Code:** 200

### Rationale

Health checks allow the load balancer to:
- Automatically detect unhealthy instances
- Stop routing traffic to failed instances
- Reintroduce instances once they recover

This removes the need for manual intervention and ensures consistent availability.

---

## Testing Methodology & Results

Testing was performed using repeated HTTP requests sent to the ALB DNS endpoint.

### Load Distribution Testing

Multiple `curl` requests were sent to the load balancer to observe which instance handled each request.

Observed behavior:
- Responses were returned from different EC2 instances
- Instance-specific identifiers rotated between requests
- Traffic was distributed across all registered, healthy instances

This confirmed that the ALB was correctly balancing traffic.

---

## Failover Scenario Documentation

Failover behavior was tested by **stopping one EC2 instance** in the target group.

Observed results:
- The stopped instance was marked as unhealthy by the ALB
- Traffic was automatically routed to the remaining healthy instances
- No application downtime was observed

When the instance was restarted:
- It passed health checks
- It was automatically added back into traffic rotation

This demonstrates correct failover and recovery behavior.

---

## Best Practices Learned

Through this implementation and testing, the following best practices were demonstrated:

- Use an Application Load Balancer as a single entry point
- Deploy application instances across multiple Availability Zones
- Use health checks to enable automatic failover
- Keep application instances private and not directly internet-facing
- Test incrementally before scaling the architecture

---

## Conclusion

The Application Load Balancer successfully distributes traffic across multiple instances, detects failures automatically, and maintains application availability. This setup reflects common real-world load balancing patterns used in production cloud environments.