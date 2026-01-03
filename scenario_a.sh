'EOF'
#!/bin/bash
echo "=== SCENARIO A: Delay/Reorder (A→C delayed by 3s) ==="
echo ""

echo "1. Clearing any existing keys..."
python3 client.py --node http://172.31.0.182:8000 put scenario_key "initial" 2>/dev/null
sleep 2

echo ""
echo "2. PUT on Node A with new value (timestamp will start fresh):"
python3 client.py --node http://172.31.0.182:8000 put scenario_key "delayed_value_A"

echo ""
echo "3. IMMEDIATELY checking Node B (should have it quickly):"
echo "   Time: $(date '+%H:%M:%S')"
result=$(python3 client.py --node http://172.31.4.134:8001 get scenario_key 2>/dev/null)
echo "   Result: $result"
if echo "$result" | grep -q "delayed_value_A"; then
    echo "   ✓ Node B has the value immediately"
else
    echo "   ✗ Node B doesn't have the value"
fi

echo ""
echo "4. IMMEDIATELY checking Node C (should be delayed 3s):"
echo "   Time: $(date '+%H:%M:%S')"
result=$(python3 client.py --node http://172.31.0.144:8002 get scenario_key 2>/dev/null)
echo "   Result: $result"
if echo "$result" | grep -q "delayed_value_A"; then
    echo "   ✓ Node C already has the value (unexpected!)"
else
    echo "   ✗ Node C doesn't have it yet (expected due to delay)"
fi

echo ""
echo "5. Waiting 4 seconds for delay to pass..."
sleep 4
echo "   Time after wait: $(date '+%H:%M:%S')"

echo ""
echo "6. Checking Node C again (should have it now):"
result=$(python3 client.py --node http://172.31.0.144:8002 get scenario_key 2>/dev/null)
echo "   Result: $result"
if echo "$result" | grep -q "delayed_value_A"; then
    echo "   ✓ Node C now has the value after delay"
else
    echo "   ✗ Node C still doesn't have the value"
fi

echo ""
EOF