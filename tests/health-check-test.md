# Failover Test Results

## Objective

To validate high availability by simulating instance failure and observing load balancer behavior.

---

## Test Procedure

1. Stopped one application EC2 instance.
2. Monitored target group health status.
3. Sent repeated `curl` requests to the Application Load Balancer.

---

## Observations

- The stopped instance was marked as "unused" in the target group.
- Remaining instances remained healthy.
- All client requests continued to receive valid responses.
- Hostname responses confirmed traffic was routed only to healthy instances.

---

## Result

PASS

The architecture successfully handled instance failure without downtime, demonstrating high availability and fault tolerance.
