'EOF'
#!/bin/bash
echo "=== SCENARIO C: Temporary Outage ==="
echo ""

echo "1. Record initial state of Node C:"
python3 client.py --node http://172.31.0.144:8002 status 2>/dev/null

echo ""
echo "2. ⚠️  MANUAL STEP: Stop Node C (Ctrl+C in Node C window)"
read -p "   Press Enter after stopping Node C..."

echo ""
echo "3. Making updates while Node C is offline:"
echo "   Update 1: key1='update1_during_outage' on Node A"
python3 client.py --node http://172.31.0.182:8000 put outage_key1 "update1_during_outage"
echo "   Update 2: key2='update2_during_outage' on Node B"
python3 client.py --node http://172.31.4.134:8001 put outage_key2 "update2_during_outage"
echo "   Update 3: key1='update3_during_outage' on Node A (overwrite)"
python3 client.py --node http://172.31.0.182:8000 put outage_key1 "update3_during_outage"
sleep 2

echo ""
echo "4. Current state of active nodes:"
echo "   Node A store:"
python3 client.py --node http://172.31.0.182:8000 status 2>/dev/null | grep -A20 '"store":'
echo ""
echo "   Node B store:"
python3 client.py --node http://172.31.4.134:8001 status 2>/dev/null | grep -A20 '"store":'

echo ""
echo "5. ⚠️  MANUAL STEP: Restart Node C"
read -p "   Press Enter after restarting Node C (python3 node.py --id C --port 8002 ...)"

echo ""
echo "6. Waiting 5 seconds..."
sleep 5

echo ""
echo "7. Trigger replication with new update:"
python3 client.py --node http://172.31.0.182:8000 put trigger_key "new_after_restart"
sleep 3

echo ""
echo "8. Checking Node C state:"
python3 client.py --node http://172.31.0.144:8002 status 2>/dev/null

echo ""
EOF