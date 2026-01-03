# Lab 2 Starter Code (Python) — 3 Nodes (A/B/C)

This starter kit implements a minimal **Lamport clock + replicated key–value store** using only the **Python standard library**.

## Files
- `node.py`  — Node server (HTTP JSON), Lamport clock, replication, LWW conflict resolution
- `client.py` — Small CLI client to PUT/GET/STATUS
- `scenario_a.sh`, `scenario_b.sh`, `scenario_c.sh` — Test scripts for required scenarios

🚀 Quick Start
## Setup EC2 Instances (3 nodes)
bash# Create 3 Ubuntu 22.04 instances (t2.micro)
# Security Group: Allow SSH (22) + Custom TCP 8000-8002 from SG itself
# Get private IPs: ip a | grep inet
## Deploy Code
bash# On each node
sudo apt update && sudo apt install -y python3
# Upload node.py and client.py via scp or git clone
## Start Nodes (use private IPs)
Node A:
bashpython3 node.py --id A --port 8000 \
  --peers http://172.31.X.Y:8001,http://172.31.X.Z:8002
Node B:
bashpython3 node.py --id B --port 8001 \
  --peers http://172.31.X.X:8000,http://172.31.X.Z:8002
Node C:
bashpython3 node.py --id C --port 8002 \
  --peers http://172.31.X.X:8000,http://172.31.X.Y:8001


## Test Basic Operations
bash# PUT on node A
python3 client.py --node http://172.31.X.X:8000 put x 10

# GET from node B (should replicate)
python3 client.py --node http://172.31.X.Y:8001 get x

# Check status on node C
python3 client.py --node http://172.31.X.Z:8002 status

## Required Scenarios
Scenario A: Delay/Reorder
Goal: Show message reordering effects with Lamport clock ordering
bash# Start Node A with 3-second delay to Node C
python3 node.py --id A --port 8000 \
  --peers http://172.31.X.Y:8001,http://172.31.X.Z:8002 \
  --delay-to http://172.31.X.Z:8002 \
  --delay-seconds 3.0

# PUT and observe timing
python3 client.py --node http://172.31.X.X:8000 put delayed "value"
python3 client.py --node http://172.31.X.Y:8001 get delayed  # Fast
python3 client.py --node http://172.31.X.Z:8002 get delayed  # Delayed 3s
Expected: Node B receives immediately, Node C receives after 3s delay. Lamport clocks maintain causal ordering.
Scenario B: Concurrent Writes
Goal: Demonstrate LWW conflict resolution with concurrent updates
bash# Send concurrent PUTs to different nodes
python3 client.py --node http://172.31.X.X:8000 put x "value_A" &
python3 client.py --node http://172.31.X.Y:8001 put x "value_B" &
wait

# Check convergence (all nodes should agree)
python3 client.py --node http://172.31.X.X:8000 get x
python3 client.py --node http://172.31.X.Y:8001 get x
python3 client.py --node http://172.31.X.Z:8002 get x
Expected: All nodes converge to the value with highest Lamport timestamp. Check server logs for "LWW: Updated" vs "LWW: Rejected" messages.
Scenario C: Temporary Outage
Goal: Show eventual consistency after node recovery
bash# 1. Stop Node C (Ctrl+C)
# 2. Make updates on A and B
python3 client.py --node http://172.31.X.X:8000 put key1 "update1"
python3 client.py --node http://172.31.X.Y:8001 put key2 "update2"

# 3. Verify A and B are in sync
python3 client.py --node http://172.31.X.X:8000 status
python3 client.py --node http://172.31.X.Y:8001 status

# 4. Restart Node C
python3 node.py --id C --port 8002 --peers http://...

# 5. Trigger replication with new update
python3 client.py --node http://172.31.X.X:8000 put trigger "new"

# 6. Check Node C (will only have new update, not missed ones)
python3 client.py --node http://172.31.X.Z:8002 status
Expected: Node C misses updates during outage (no catch-up mechanism). Only new updates replicate. Demonstrates need for anti-entropy.
