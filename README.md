# Lab M3.03 - Create Load Balancer with Health Checks

**Repository:** [https://github.com/cloud-engineering-bootcamp/ce-lab-load-balancer-health-checks](https://github.com/cloud-engineering-bootcamp/ce-lab-load-balancer-health-checks)

**Activity Type:** Individual  
**Estimated Time:** 60-75 minutes

## Learning Objectives

- [ ] Create and configure Application Load Balancer
- [ ] Set up Target Groups with health checks
- [ ] Deploy multiple web servers across availability zones
- [ ] Configure listener rules and routing
- [ ] Test load distribution and failover behavior
- [ ] Implement connection draining

## Your Task

Build a highly available web application with load balancing:
1. Launch 3 web servers across 2 AZs
2. Create Application Load Balancer in public subnets
3. Configure target group with health check endpoint
4. Test traffic distribution and health check failover
5. Document load balancer architecture

**Success Criteria:** Load balancer distributes traffic evenly and removes unhealthy instances.

## 📤 What to Submit

**Submission Type:** GitHub Repository

Create a **public** GitHub repository named `ce-lab-load-balancer` containing:

### Required Files

**1. README.md**
- Load balancer architecture explanation
- Health check configuration and rationale
- Testing methodology and results
- Failover scenario documentation
- Best practices learned

**2. Application Code** (`app/` folder)
- `server.js` or `app.py` - Simple web application
- `/health` endpoint implementation
- `index.html` - Homepage showing instance ID

**3. Configuration** (`config/` folder)
- `alb-config.txt` - Load balancer settings
- `target-group-config.txt` - Target group details
- `health-check-config.txt` - Health check parameters
- `listener-rules.txt` - Routing configuration

**4. Test Results** (`tests/` folder)
- `load-distribution-test.md` - Traffic distribution analysis
- `health-check-test.md` - Health check failover test
- `test-commands.sh` - Curl/testing scripts used

**5. Screenshots** (`screenshots/` folder)
- ALB dashboard
- Target group with healthy targets
- Target group with one unhealthy target
- Browser showing responses from different servers
- CloudWatch metrics

## Grading: 100 points

- Load balancer properly configured: 25pts
- Target group and health checks: 25pts
- Multi-AZ deployment: 20pts
- Testing demonstrates failover: 20pts
- Documentation quality: 10pts

## Quick Start

```bash
# 1. Launch 3 EC2 instances with web server
# (Use user data script below)

# 2. Create Target Group
aws elbv2 create-target-group \
  --name web-servers-tg \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-xxxxx \
  --health-check-path /health \
  --health-check-interval-seconds 10

# 3. Register instances
aws elbv2 register-targets \
  --target-group-arn arn:aws:... \
  --targets Id=i-xxxxx Id=i-yyyyy Id=i-zzzzz

# 4. Create Application Load Balancer
aws elbv2 create-load-balancer \
  --name web-alb \
  --subnets subnet-public-1a subnet-public-1b \
  --security-groups sg-xxxxx

# 5. Create Listener
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:... \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=arn:aws:...
```

## Detailed Instructions

### Part 1: Prepare Web Server Script (10 min)

**User Data Script** (Node.js version):
```bash
#!/bin/bash
yum update -y
yum install -y nodejs git

# Get instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

# Create simple web server
cat > /home/ec2-user/server.js <<'EOF'
const http = require('http');
const os = require('os');

const INSTANCE_ID = process.env.INSTANCE_ID || 'unknown';
const AZ = process.env.AZ || 'unknown';

const server = http.createServer((req, res) => {
  // Health check endpoint
  if (req.url === '/health') {
    res.writeHead(200, {'Content-Type': 'application/json'});
    res.end(JSON.stringify({
      status: 'healthy',
      instance: INSTANCE_ID,
      az: AZ,
      uptime: process.uptime()
    }));
    return;
  }
  
  // Main page
  res.writeHead(200, {'Content-Type': 'text/html'});
  res.end(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Load Balanced App</title>
      <style>
        body { font-family: Arial; text-align: center; padding: 50px; background: #f0f0f0; }
        .container { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .instance { color: #007bff; font-size: 24px; font-weight: bold; }
        .az { color: #28a745; font-size: 18px; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🚀 Cloud Engineering Bootcamp</h1>
        <h2>Load Balanced Application</h2>
        <p class="instance">Instance: ${INSTANCE_ID}</p>
        <p class="az">Availability Zone: ${AZ}</p>
        <p>Hostname: ${os.hostname()}</p>
        <p>Request count handled: ${Math.floor(Math.random() * 1000)}</p>
      </div>
    </body>
    </html>
  `);
});

server.listen(80, () => {
  console.log(`Server running on port 80 (Instance: ${INSTANCE_ID}, AZ: ${AZ})`);
});
EOF

# Set environment variables and run server
export INSTANCE_ID=$INSTANCE_ID
export AZ=$AZ
cd /home/ec2-user
nohup node server.js > server.log 2>&1 &
```

**Alternative: Python + Flask:**
```bash
#!/bin/bash
yum update -y
yum install -y python3 python3-pip

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

pip3 install flask

cat > /home/ec2-user/app.py <<EOF
from flask import Flask, jsonify
import os

app = Flask(__name__)
INSTANCE_ID = os.environ.get('INSTANCE_ID', 'unknown')
AZ = os.environ.get('AZ', 'unknown')

@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'instance': INSTANCE_ID,
        'az': AZ
    })

@app.route('/')
def home():
    return f"""
    <html>
      <head><title>Load Balanced App</title></head>
      <body style="font-family: Arial; text-align: center; padding: 50px;">
        <h1>Load Balanced Application</h1>
        <p><strong>Instance:</strong> {INSTANCE_ID}</p>
        <p><strong>AZ:</strong> {AZ}</p>
      </body>
    </html>
    """

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
EOF

export INSTANCE_ID=$INSTANCE_ID
export AZ=$AZ
cd /home/ec2-user
nohup python3 app.py > app.log 2>&1 &
```

### Part 2: Create Security Groups (10 min)

**ALB Security Group:**
```bash
ALB_SG=$(aws ec2 create-security-group \
  --group-name alb-sg \
  --description "Security group for Application Load Balancer" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

# Allow HTTP from anywhere
aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG \
  --protocol tcp --port 80 --cidr 0.0.0.0/0
```

**Web Server Security Group:**
```bash
WEB_SG=$(aws ec2 create-security-group \
  --group-name web-servers-sg \
  --description "Security group for web servers" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

# Allow HTTP from ALB only
aws ec2 authorize-security-group-ingress \
  --group-id $WEB_SG \
  --protocol tcp --port 80 --source-group $ALB_SG
```

### Part 3: Launch EC2 Instances (15 min)

**Launch Instance 1 (AZ-A):**
```bash
INSTANCE_1=$(aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --key-name your-key-pair \
  --security-group-ids $WEB_SG \
  --subnet-id $PRIVATE_SUBNET_1 \
  --user-data file://userdata.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-server-1a}]' \
  --query 'Instances[0].InstanceId' --output text)
```

**Launch Instance 2 (AZ-A):**
```bash
INSTANCE_2=$(aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --key-name your-key-pair \
  --security-group-ids $WEB_SG \
  --subnet-id $PRIVATE_SUBNET_1 \
  --user-data file://userdata.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-server-1a-2}]' \
  --query 'Instances[0].InstanceId' --output text)
```

**Launch Instance 3 (AZ-B):**
```bash
INSTANCE_3=$(aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --key-name your-key-pair \
  --security-group-ids $WEB_SG \
  --subnet-id $PRIVATE_SUBNET_2 \
  --user-data file://userdata.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-server-1b}]' \
  --query 'Instances[0].InstanceId' --output text)
```

### Part 4: Create Target Group (10 min)

```bash
TG_ARN=$(aws elbv2 create-target-group \
  --name web-servers-tg \
  --protocol HTTP \
  --port 80 \
  --vpc-id $VPC_ID \
  --health-check-protocol HTTP \
  --health-check-path /health \
  --health-check-interval-seconds 10 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 2 \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

echo "Target Group ARN: $TG_ARN"
```

**Register Instances:**
```bash
aws elbv2 register-targets \
  --target-group-arn $TG_ARN \
  --targets Id=$INSTANCE_1 Id=$INSTANCE_2 Id=$INSTANCE_3

# Wait for health checks
sleep 30

# Check target health
aws elbv2 describe-target-health --target-group-arn $TG_ARN
```

### Part 5: Create Application Load Balancer (10 min)

```bash
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name web-alb \
  --subnets $PUBLIC_SUBNET_1 $PUBLIC_SUBNET_2 \
  --security-groups $ALB_SG \
  --scheme internet-facing \
  --type application \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)

echo "ALB ARN: $ALB_ARN"

# Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --query 'LoadBalancers[0].DNSName' --output text)

echo "ALB DNS: $ALB_DNS"
```

### Part 6: Create Listener (5 min)

```bash
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN

echo "Listener created!"
```

### Part 7: Test Load Balancer (15 min)

**Test 1: Basic Connectivity**
```bash
# Wait for ALB to be active
sleep 60

# Test ALB endpoint
curl http://$ALB_DNS

# Should see response from one of the instances
```

**Test 2: Load Distribution**
```bash
# Make 20 requests and see distribution
for i in {1..20}; do
  curl -s http://$ALB_DNS | grep "Instance:" | sed 's/.*Instance: //'
done | sort | uniq -c

# Expected output:
#   7 i-abc123
#   6 i-def456
#   7 i-ghi789
# (Roughly even distribution)
```

**Test 3: Health Check Endpoint**
```bash
curl http://$ALB_DNS/health

# Should return JSON:
# {"status":"healthy","instance":"i-xxxxx","az":"us-east-1a","uptime":123}
```

**Test 4: Simulate Instance Failure**
```bash
# Stop one instance
aws ec2 stop-instances --instance-ids $INSTANCE_1

# Wait 30 seconds for health check to mark unhealthy
sleep 30

# Check target health
aws elbv2 describe-target-health --target-group-arn $TG_ARN
# Should show instance 1 as unhealthy

# Test load distribution (should only use 2 instances now)
for i in {1..10}; do
  curl -s http://$ALB_DNS | grep "Instance:" | sed 's/.*Instance: //'
done | sort | uniq -c

# Expected: Only 2 instances receive traffic
```

**Test 5: Verify Failover**
```bash
# Restart stopped instance
aws ec2 start-instances --instance-ids $INSTANCE_1

# Wait for health check to mark healthy again
sleep 60

# Verify all 3 instances back in rotation
aws elbv2 describe-target-health --target-group-arn $TG_ARN
```

## Reflection Questions

Answer in your README:

1. **How does the load balancer know if an instance is healthy?**

2. **What happens when an instance fails a health check?**

3. **Why deploy instances across multiple Availability Zones?**

4. **What is the purpose of the /health endpoint?**

5. **How would you implement sticky sessions? When would you need them?**

## Bonus Challenges

**+5 points each:**
- [ ] Implement HTTPS listener with ACM certificate
- [ ] Add path-based routing (/api/* → different target group)
- [ ] Configure connection draining (deregistration delay)
- [ ] Set up CloudWatch alarms for unhealthy hosts
- [ ] Implement Auto Scaling with the target group

## Troubleshooting

**Issue: Targets showing unhealthy**
```bash
# Check:
- [ ] Security group allows traffic from ALB
- [ ] Application is running on port 80
- [ ] /health endpoint returns 200 OK
- [ ] Health check path is correct
- [ ] Instances have finished initializing (user data complete)
```

**Issue: Can't access ALB**
```bash
# Check:
- [ ] ALB security group allows inbound port 80
- [ ] ALB is in public subnets
- [ ] Public subnets have route to Internet Gateway
- [ ] ALB state is "active"
```

**Issue: Uneven load distribution**
```bash
# This is normal! ALB uses least outstanding requests algorithm
# Distribution won't be perfectly even
# Over time (hundreds of requests), it evens out
```

## Resources

- [ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [Health Checks](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-health-checks.html)
- [Target Groups](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html)

---

**Congratulations on building a highly available load balanced application!** 🎉
